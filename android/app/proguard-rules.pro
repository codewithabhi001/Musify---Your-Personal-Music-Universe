# Keep just_audio classes
-keep class com.ryanheise.** { *; }
-dontwarn com.ryanheise.**

# Keep audiotags classes
-keep class com.judemanutd.** { *; }
-dontwarn com.judemanutd.**

# Keep Flutter and plugin classes
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Keep audio session classes
-keep class androidx.media.** { *; }
-dontwarn androidx.media.**

# Keep permission_handler classes
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Keep MainActivity and method channel classes
-keep class com.example.musify.MainActivity { *; }
-keep class **.MainActivity { *; }

# Keep Android media classes
-keep class android.media.** { *; }
-dontwarn android.media.**

# Keep ExoPlayer classes (used by just_audio)
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Keep MediaSession classes
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.** { *; }
-dontwarn android.support.v4.media.**

# Keep notification classes for Android 13+
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class android.app.Notification** { *; }

# Keep method channel related classes
-keep class io.flutter.plugin.common.** { *; }
-dontwarn io.flutter.plugin.common.**

# Keep JSON classes for method channel data
-keep class org.json.** { *; }
-dontwarn org.json.**
