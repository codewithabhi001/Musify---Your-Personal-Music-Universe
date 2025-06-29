package com.example.musify

import android.Manifest
import android.content.pm.PackageManager
import android.database.Cursor
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.example.musify/audio"
    private val TAG = "MusifyMainActivity"
    private val PERMISSION_REQUEST_CODE = 123

    private val BLACKLISTED_DIRS =
            listOf(
                    "WhatsApp",
                    "Recorder",
                    "Recordings",
                    "Voice",
                    "Call",
                    "Telegram",
                    "Signal",
                    "Viber",
                    "Skype"
            )
    private val BLACKLISTED_EXTENSIONS = listOf("opus", "amr", "m4r", "3gp", "awb")

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "getSongs" -> {
                    if (hasStoragePermission()) {
                        Thread {
                                    try {
                                        val songs = getSongsFromMediaStore()
                                        runOnUiThread { result.success(songs) }
                                    } catch (e: Exception) {
                                        Log.e(TAG, "Error fetching songs: ${e.message}", e)
                                        runOnUiThread {
                                            result.error(
                                                    "FETCH_ERROR",
                                                    "Failed to fetch songs: ${e.message}",
                                                    null
                                            )
                                        }
                                    }
                                }
                                .start()
                    } else {
                        requestStoragePermission()
                        result.error("PERMISSION_DENIED", "Storage permission not granted", null)
                    }
                }
                "retryFetchSongs" -> {
                    if (hasStoragePermission()) {
                        Thread {
                                    try {
                                        val songs = getSongsFromMediaStore()
                                        runOnUiThread { result.success(songs) }
                                    } catch (e: Exception) {
                                        Log.e(TAG, "Error retrying fetch: ${e.message}", e)
                                        runOnUiThread {
                                            result.error(
                                                    "FETCH_ERROR",
                                                    "Failed to retry fetch: ${e.message}",
                                                    null
                                            )
                                        }
                                    }
                                }
                                .start()
                    } else {
                        result.error(
                                "PERMISSION_DENIED",
                                "Storage permission still not granted",
                                null
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun hasStoragePermission(): Boolean {
        val permissions =
                when {
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU ->
                            arrayOf(Manifest.permission.READ_MEDIA_AUDIO)
                    else -> arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
                }
        return permissions.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestStoragePermission() {
        val permissions =
                when {
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU ->
                            arrayOf(Manifest.permission.READ_MEDIA_AUDIO)
                    else -> arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE)
                }
        ActivityCompat.requestPermissions(this, permissions, PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
            requestCode: Int,
            permissions: Array<out String>,
            grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE &&
                        grantResults.isNotEmpty() &&
                        grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        ) {
            flutterEngine?.let {
                MethodChannel(it.dartExecutor.binaryMessenger, CHANNEL)
                        .invokeMethod("retryFetchSongs", null)
            }
                    ?: Log.e(TAG, "Flutter engine is null during permission result")
        }
    }

    private fun getSongsFromMediaStore(): List<Map<String, Any?>> {
        val songs = mutableListOf<Map<String, Any?>>()
        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
        val projection =
                arrayOf(
                        MediaStore.Audio.Media.DATA,
                        MediaStore.Audio.Media.TITLE,
                        MediaStore.Audio.Media.ARTIST,
                        MediaStore.Audio.Media.ALBUM,
                        MediaStore.Audio.Media.DATE_ADDED,
                        MediaStore.Audio.Media.DURATION
                )
        val selection =
                "${MediaStore.Audio.Media.IS_MUSIC} != 0 AND ${MediaStore.Audio.Media.DURATION} >= 10000"

        val cursor: Cursor? =
                try {
                    contentResolver.query(
                            uri,
                            projection,
                            selection,
                            null,
                            "${MediaStore.Audio.Media.DATE_ADDED} DESC"
                    )
                } catch (e: Exception) {
                    Log.e(TAG, "Error querying MediaStore: ${e.message}", e)
                    return emptyList()
                }

        cursor?.use {
            val pathCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val titleCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val dateCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            val durationCol = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)

            while (it.moveToNext()) {
                val path = it.getString(pathCol) ?: continue
                val file = File(path)
                if (!file.exists() || file.length() < 50 * 1024) continue

                val isBlacklistedDir =
                        BLACKLISTED_DIRS.any { dir -> path.contains("/$dir/", ignoreCase = true) }
                val isBlacklistedExt =
                        BLACKLISTED_EXTENSIONS.any { ext ->
                            path.endsWith(".$ext", ignoreCase = true)
                        }

                if (isBlacklistedDir || isBlacklistedExt) continue

                songs.add(
                        mapOf(
                                "path" to path,
                                "title" to it.getString(titleCol),
                                "artist" to it.getString(artistCol),
                                "album" to it.getString(albumCol),
                                "dateAdded" to it.getLong(dateCol) * 1000,
                                "duration" to it.getLong(durationCol)
                        )
                )
            }
        }
        return songs
    }
}
