package com.example.musify

import android.Manifest
import android.content.ContentResolver
import android.content.pm.PackageManager
import android.database.Cursor
import android.os.Build
import android.provider.MediaStore
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.musify/audio"
    private val TAG = "MusifyMainActivity"
    private val PERMISSION_REQUEST_CODE = 123gg

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
        val permission =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    Manifest.permission.READ_MEDIA_AUDIO
                } else {
                    Manifest.permission.READ_EXTERNAL_STORAGE
                }
        return ContextCompat.checkSelfPermission(this, permission) ==
                PackageManager.PERMISSION_GRANTED
    }

    private fun requestStoragePermission() {
        val permission =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    Manifest.permission.READ_MEDIA_AUDIO
                } else {
                    Manifest.permission.READ_EXTERNAL_STORAGE
                }
        ActivityCompat.requestPermissions(this, arrayOf(permission), PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
            requestCode: Int,
            permissions: Array<out String>,
            grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE &&
                        grantResults.isNotEmpty() &&
                        grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
                    .invokeMethod("retryFetchSongs", null)
        }
    }

    private fun getSongsFromMediaStore(): List<Map<String, Any?>> {
        val songs = mutableListOf<Map<String, Any?>>()
        val contentResolver: ContentResolver = contentResolver
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
            val pathColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val titleColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val dateAddedColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            val durationColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)

            while (it.moveToNext()) {
                val path = it.getString(pathColumn) ?: continue
                val file = File(path)
                if (!file.exists() || file.length() < 1024 * 50) continue

                if (BLACKLISTED_DIRS.any { dir -> path.contains("/$dir/", ignoreCase = true) } ||
                                BLACKLISTED_EXTENSIONS.contains(
                                        path.substringAfterLast('.', "").lowercase()
                                )
                ) {
                    continue
                }

                val song =
                        mapOf<String, Any?>(
                                "path" to path,
                                "title" to it.getString(titleColumn),
                                "artist" to it.getString(artistColumn),
                                "album" to it.getString(albumColumn),
                                "dateAdded" to
                                        (if (it.isNull(dateAddedColumn)) null
                                        else it.getLong(dateAddedColumn)),
                                "duration" to
                                        (if (it.isNull(durationColumn)) null
                                        else it.getLong(durationColumn))
                        )
                songs.add(song)
            }
        }

        return songs
    }
}
