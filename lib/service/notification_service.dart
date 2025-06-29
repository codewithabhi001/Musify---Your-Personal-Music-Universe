import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get/get.dart';
import 'package:musify/controllers/player_controller.dart';
import 'package:musify/controllers/song_controller.dart';

class NotificationService extends GetxController {
  final AudioPlayer _player;
  final SongController _songController = Get.find<SongController>();
  static const String channelKey = 'musify_playback';
  static const String notificationId = 'musify_media_notification';
  Timer? _debounceTimer;
  bool _isUpdating = false;
  String? _lastTitle;
  String? _lastArtist;
  String? _lastAlbum;
  String? _lastImagePath;
  bool? _lastIsPlaying;

  NotificationService(this._player) {
    _init();
  }

  Future<void> _init() async {
    // Initialize Awesome Notifications
    await AwesomeNotifications().initialize(
      'resource://drawable/app_icon', // Ensure app_icon.png exists in android/app/src/main/res/drawable/
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: 'Musify Playback',
          channelDescription: 'Media playback controls for Musify',
          defaultColor: Colors.blue, // Material UI-inspired color
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          playSound: false,
          enableVibration: false,
          channelShowBadge: false,
          locked: true, // Keep notification pinned
          enableLights: true,
          defaultPrivacy: NotificationPrivacy.Public,
        ),
      ],
      debug: true,
    );

    // Request notification permission
    await AwesomeNotifications().requestPermissionToSendNotifications();

    // Set notification action listeners
    await startListeningNotificationEvents();
  }

  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: onActionReceivedMethod,
    );
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.channelKey == channelKey) {
      final playerController = Get.find<PlayerController>();
      switch (receivedAction.buttonKeyPressed) {
        case 'play_pause':
          await playerController.togglePlayPause();
          break;
        case 'skip_previous':
          await playerController.skipToPrevious();
          break;
        case 'skip_next':
          await playerController.skipToNext();
          break;
      }
    }
  }

  Future<void> showMediaNotification({
    required String title,
    required String artist,
    String? album,
    String? imagePath,
    bool isPlaying = false,
  }) async {
    try {
      // Truncate title and artist to prevent overflow (max 30 characters)
      final truncatedTitle =
          title.length > 30 ? '${title.substring(0, 27)}...' : title;
      final truncatedArtist =
          artist.length > 30 ? '${artist.substring(0, 27)}...' : artist;
      final largeIconPath = imagePath != null && await File(imagePath).exists()
          ? imagePath
          : 'resource://drawable/music_note'; // Fallback to music_note icon

      // Check if notification needs updating
      if (_lastTitle == truncatedTitle &&
          _lastArtist == truncatedArtist &&
          _lastAlbum == album &&
          _lastImagePath == largeIconPath &&
          _lastIsPlaying == isPlaying) {
        return; // Skip update if no changes
      }

      _lastTitle = truncatedTitle;
      _lastArtist = truncatedArtist;
      _lastAlbum = album;
      _lastImagePath = largeIconPath;
      _lastIsPlaying = isPlaying;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId.hashCode,
          channelKey: channelKey,
          title: truncatedTitle,
          body: truncatedArtist + (album != null ? ' • $album' : ''),
          largeIcon: largeIconPath != null ? 'file://$largeIconPath' : null,
          bigPicture: largeIconPath != null ? 'file://$largeIconPath' : null,
          notificationLayout:
              NotificationLayout.Default, // Use BigPicture for image background
          color: Colors.transparent, // Attempt transparency
          backgroundColor:
              Colors.black.withOpacity(0.3), // Semi-transparent dark overlay
          showWhen: true,
          roundedBigPicture: true,
          roundedLargeIcon: true,
          category: NotificationCategory.Social,
          wakeUpScreen: true,
          locked: true,
          autoDismissible: false,
          displayOnForeground: true,
          displayOnBackground: true,
          payload: {'id': notificationId},
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'skip_previous',
            label: 'Previous',
            icon: 'resource://drawable/res_skip_previous',
            enabled: true,
            autoDismissible: false,
            color: Colors.white,
          ),
          NotificationActionButton(
            key: 'play_pause',
            label: isPlaying ? 'Pause' : 'Play',
            icon: isPlaying
                ? 'resource://drawable/res_pause'
                : 'resource://drawable/res_play',
            enabled: true,
            autoDismissible: false,
            color: Colors.white,
          ),
          NotificationActionButton(
            key: 'skip_next',
            label: 'Next',
            icon: 'resource://drawable/res_skip_next',
            enabled: true,
            autoDismissible: false,
            color: Colors.white,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  Future<File?> _saveAlbumArtTemp(Uint8List data, String songPath) async {
    try {
      final tempDir = Directory.systemTemp;
      final fileName = 'album_art_${songPath.hashCode}.png';
      final file = File('${tempDir.path}/$fileName');

      if (await file.exists()) {
        return file;
      }

      await file.writeAsBytes(data);
      return file;
    } catch (e) {
      debugPrint('Error saving album art: $e');
      return null;
    }
  }

  Future<void> updateNotification() async {
    if (_isUpdating) return;

    _isUpdating = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () async {
      try {
        final controller = Get.find<PlayerController>();
        if (controller.currentSong.value == null) {
          await clearNotification();
          return;
        }

        final song = controller.currentSong.value!;
        String? imagePath;

        final albumArtData = await _songController.loadAlbumArt(song.path);
        if (albumArtData != null) {
          final file = await _saveAlbumArtTemp(albumArtData, song.path);
          imagePath = file?.path;
        }

        await showMediaNotification(
          title: song.title,
          artist: song.artist ?? 'Unknown Artist',
          album: song.album,
          imagePath: imagePath,
          isPlaying: controller.isPlaying.value,
        );
      } finally {
        _isUpdating = false;
      }
    });
  }

  Future<void> clearNotification() async {
    _lastTitle = null;
    _lastArtist = null;
    _lastAlbum = null;
    _lastImagePath = null;
    _lastIsPlaying = null;
    await AwesomeNotifications().cancel(notificationId.hashCode);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    clearNotification();
    super.dispose();
  }
}
