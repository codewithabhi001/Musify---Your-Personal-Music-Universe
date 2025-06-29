# Keep Awesome Notifications classes and resources
-keep class com.bitvale.awesome_notifications.** { *; }
-keep interface com.bitvale.awesome_notifications.** { *; }
-dontwarn com.bitvale.awesome_notifications.**

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

# Keep file-related classes for temporary file handling
-keep class java.io.File { *; }
-dontwarn java.io.File