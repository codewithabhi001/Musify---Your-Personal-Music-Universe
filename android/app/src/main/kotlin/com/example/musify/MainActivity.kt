package com.example.musify

import android.Manifest
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject
import android.os.Environment

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.musify/songs"
    private val PERMISSION_REQUEST_CODE = 1001

    // Only block system recordings and very specific non-music files
    private val BLACKLISTED_DIRS = listOf(
        "Android/data/com.android.soundrecorder",
        "Android/data/com.google.android.apps.recorder",
        "Android/data/com.samsung.android.voice.recorder",
        "Android/data/com.sec.android.app.voicenote",
        "Recordings",
        "Voice Recorder",
        "Call Recorder"
    )

    // Only block very specific non-music formats
    private val BLACKLISTED_EXTENSIONS = listOf(
        "amr", "awb", "3gp" // Only block voice recording formats
    )

    // Allow all common music formats including downloaded ones
    private val ALLOWED_EXTENSIONS = listOf(
        "mp3", "m4a", "flac", "wma", "aiff", "ogg", "wav", "aac", "opus"
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSongs" -> {
                    result.success(getSongsFromDevice())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getSongsFromDevice(): String {
        // Check permissions first
        if (!hasRequiredPermissions()) {
            return JSONArray().toString()
        }
        
        val songs = JSONArray()
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.TRACK,
            MediaStore.Audio.Media.YEAR,
            MediaStore.Audio.Media.GENRE,
            MediaStore.Audio.Media.MIME_TYPE
        )

        // More permissive selection - include all audio files with duration >= 10 seconds
        val selection = "${MediaStore.Audio.Media.DURATION} >= 10000"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} ASC"

        val cursor: Cursor? = contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection,
            selection,
            null,
            sortOrder
        )

        cursor?.use { 
            val idColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val titleColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val artistColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val albumColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val dataColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val durationColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val trackColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.TRACK)
            val yearColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.YEAR)
            val genreColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.GENRE)
            val mimeTypeColumn = it.getColumnIndexOrThrow(MediaStore.Audio.Media.MIME_TYPE)

            while (it.moveToNext()) {
                val filePath = it.getString(dataColumn)
                
                // Skip if file path is null
                if (filePath == null) continue
                
                // Check if file is blacklisted (only very specific system recordings)
                if (isBlacklisted(filePath)) continue
                
                // Check if file has allowed extension (very permissive)
                if (!hasAllowedExtension(filePath)) continue
                
                // Check if duration is valid (at least 10 seconds)
                val duration = it.getLong(durationColumn)
                if (duration < 10000) continue

                val song = JSONObject()
                song.put("id", it.getLong(idColumn).toString())
                song.put("title", it.getString(titleColumn) ?: "Unknown Title")
                song.put("artist", it.getString(artistColumn) ?: "Unknown Artist")
                song.put("album", it.getString(albumColumn) ?: "Unknown Album")
                song.put("path", filePath)
                song.put("duration", duration)
                song.put("trackNumber", if (!it.isNull(trackColumn)) it.getInt(trackColumn) else null)
                song.put("year", if (!it.isNull(yearColumn)) it.getInt(yearColumn) else null)
                song.put("genre", it.getString(genreColumn))
                song.put("isFavorite", false)
                
                songs.put(song)
            }
        }

        return songs.toString()
    }
    
    private fun hasRequiredPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Android 13+ - Check for READ_MEDIA_AUDIO permission
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.READ_MEDIA_AUDIO
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            // Android 12 and below - Check for READ_EXTERNAL_STORAGE permission
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.READ_EXTERNAL_STORAGE
            ) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun isBlacklisted(filePath: String): Boolean {
        val lowerPath = filePath.lowercase()
        
        // Only check for very specific system recording directories
        for (dir in BLACKLISTED_DIRS) {
            if (lowerPath.contains(dir.lowercase())) {
                return true
            }
        }
        
        return false
    }

    private fun hasAllowedExtension(filePath: String): Boolean {
        val extension = filePath.substringAfterLast('.', "").lowercase()
        
        // If it's a blacklisted extension, reject it
        if (BLACKLISTED_EXTENSIONS.contains(extension)) {
            return false
        }
        
        // If it's an allowed extension, accept it
        if (ALLOWED_EXTENSIONS.contains(extension)) {
            return true
        }
        
        // For any other extension, also accept it (more permissive)
        return true
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Permission granted, you can now fetch songs
            }
        }
    }
}
