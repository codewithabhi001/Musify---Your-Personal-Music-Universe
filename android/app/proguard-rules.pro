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