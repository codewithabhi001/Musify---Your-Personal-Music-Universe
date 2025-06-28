// import 'dart:io';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:get/get.dart';
// import 'package:musify/controllers/player_controller.dart';

// class NotificationService {
//   static final FlutterLocalNotificationsPlugin
//       _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//   static final PlayerController? _playerController =
//       Get.isRegistered<PlayerController>()
//           ? Get.find<PlayerController>()
//           : null;

//   static Future<void> initialize() async {
//     print('Initializing NotificationService...');
//     try {
//       // Use ic_launcher as a fallback icon (default app icon)
//       const AndroidInitializationSettings initializationSettingsAndroid =
//           AndroidInitializationSettings('@mipmap/ic_launcher');
//       final DarwinInitializationSettings initializationSettingsDarwin =
//           DarwinInitializationSettings();
//       final InitializationSettings initializationSettings =
//           InitializationSettings(
//         android: initializationSettingsAndroid,
//         iOS: initializationSettingsDarwin,
//       );
//       await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
//           onDidReceiveNotificationResponse: _onNotificationTap);
//       print('NotificationService initialized successfully');
//     } catch (e) {
//       print('NotificationService initialization failed with fallback icon: $e');
//       // Attempt to initialize without an icon if fallback fails
//       try {
//         final AndroidInitializationSettings noIconSettings =
//             AndroidInitializationSettings(''); // No icon
//         final InitializationSettings noIconSettingsInit =
//             InitializationSettings(
//                 android: noIconSettings, iOS: DarwinInitializationSettings());
//         await _flutterLocalNotificationsPlugin.initialize(noIconSettingsInit,
//             onDidReceiveNotificationResponse: _onNotificationTap);
//         print('NotificationService initialized successfully without icon');
//       } catch (e2) {
//         print('NotificationService initialization completely failed: $e2');
//       }
//     }
//   }

//   static void _showNotification() {
//     print('Attempting to show notification...');
//     if (_playerController == null) {
//       print('PlayerController is null');
//       return;
//     }
//     if (_playerController!.currentSong.value == null) {
//       print('Current song is null');
//       return;
//     }

//     const AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'music_channel',
//       'Music Player',
//       channelDescription: 'Notification for music playback',
//       importance: Importance.high,
//       priority: Priority.high,
//       playSound: true,
//       enableVibration: true,
//       actions: [
//         AndroidNotificationAction('play', 'Play', showsUserInterface: true),
//         AndroidNotificationAction('pause', 'Pause', showsUserInterface: true),
//       ],
//     );
//     const NotificationDetails platformChannelSpecifics =
//         NotificationDetails(android: androidPlatformChannelSpecifics);

//     final song = _playerController!.currentSong.value!;
//     print(
//         'Showing notification for song: ${song.title} by ${song.artist ?? 'Unknown Artist'}');
//     try {
//       _flutterLocalNotificationsPlugin.show(
//         0,
//         'Now Playing: ${song.title}',
//         song.artist ?? 'Unknown Artist',
//         platformChannelSpecifics,
//         payload: 'music_playing',
//       );
//       print('Notification shown successfully');
//     } catch (e) {
//       print('Failed to show notification: $e');
//     }
//   }

//   static void _updateNotification() {
//     print('Updating notification...');
//     if (_playerController == null) {
//       print('PlayerController is null');
//       _stopNotification();
//       return;
//     }
//     if (_playerController!.currentSong.value == null) {
//       print('Current song is null');
//       _stopNotification();
//       return;
//     }
//     _flutterLocalNotificationsPlugin.cancel(0);
//     if (_playerController!.isPlaying.value) {
//       print('Player is playing, showing notification');
//       _showNotification();
//     } else {
//       print('Player is not playing, stopping notification');
//       _stopNotification();
//     }
//   }

//   static void _stopNotification() {
//     print('Stopping notification...');
//     try {
//       _flutterLocalNotificationsPlugin.cancel(0);
//       print('Notification stopped successfully');
//     } catch (e) {
//       print('Failed to stop notification: $e');
//     }
//   }

//   static void _onNotificationTap(NotificationResponse notificationResponse) {
//     print('Notification tapped: ${notificationResponse.actionId}');
//     if (_playerController == null) {
//       print('PlayerController is null, cannot handle tap');
//       return;
//     }
//     if (notificationResponse.actionId == 'play') {
//       print('Resuming playback');
//       _playerController!.resume();
//     } else if (notificationResponse.actionId == 'pause') {
//       print('Pausing playback');
//       _playerController!.pause();
//     }
//     _updateNotification();
//   }

//   static void setupListener() {
//     print('Setting up notification listener...');
//     if (_playerController == null) {
//       print('PlayerController is null, listener not set up');
//       return;
//     }
//     _playerController!.playingStream.listen(
//       (isPlaying) {
//         print('Playing stream changed to: $isPlaying');
//         if (isPlaying && _playerController!.currentSong.value != null) {
//           print('Song is playing, showing notification');
//           _showNotification();
//         } else {
//           print('Song is not playing or no song, updating notification');
//           _updateNotification();
//         }
//       },
//       onError: (e) {
//         print('Error in playingStream: $e');
//       },
//     );
//     _playerController!.currentSongStream.listen(
//       (song) {
//         print('Current song stream changed to: ${song?.title ?? 'null'}');
//         _updateNotification();
//       },
//       onError: (e) {
//         print('Error in currentSongStream: $e');
//       },
//     );
//     print('Notification listener set up successfully');
//   }
// }
