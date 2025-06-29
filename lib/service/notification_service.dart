import 'dart:async';
import 'dart:io';
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

  NotificationService(this._player) {
    _init();
  }

  Future<void> _init() async {
    // Initialize Awesome Notifications
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: channelKey,
          channelName: 'Musify Playback',
          channelDescription: 'Media playback controls for Musify',
          defaultColor: Colors.blue,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          playSound: false,
          enableVibration: false,
          channelShowBadge: false,
          locked: true,
        ),
      ],
      debug: true,
    );

    // Request notification permission
    await AwesomeNotifications().requestPermissionToSendNotifications();

    // Set notification action listeners
    await startListeningNotificationEvents();

    // Update notification on player state changes
    _player.playingStream.listen((playing) {
      updateNotification();
    });

    _player.positionStream.listen((position) {
      updateNotification();
    });

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        Get.find<PlayerController>().handleSongCompletion();
      }
      updateNotification();
    });
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
          if (playerController.isPlaying.value) {
            await playerController.pause();
          } else {
            await playerController.resume();
          }
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
      final largeIconPath =
          imagePath != null && File(imagePath).existsSync() ? imagePath : null;

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId.hashCode,
          channelKey: channelKey,
          title: title,
          body: artist + (album != null ? ' • $album' : ''),
          largeIcon: largeIconPath != null ? 'file://$largeIconPath' : null,
          notificationLayout: NotificationLayout.MediaPlayer,
          category: NotificationCategory.Transport,
          wakeUpScreen: true,
          locked: true,
          payload: {'id': notificationId},
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'skip_previous',
            label: 'Previous',
            icon: 'asset://assets/res_skip_previous.png',
            enabled: true,
          ),
          NotificationActionButton(
            key: 'play_pause',
            label: isPlaying ? 'Pause' : 'Play',
            icon: isPlaying
                ? 'asset://assets/res_pause.png'
                : 'asset://assets/res_play.png',
            enabled: true,
          ),
          NotificationActionButton(
            key: 'skip_next',
            label: 'Next',
            icon: 'asset://assets/res_skip_next.png',
            enabled: true,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  Future<void> updateNotification() async {
    final controller = Get.find<PlayerController>();
    if (controller.currentSong.value == null) {
      await clearNotification();
      return;
    }

    final song = controller.currentSong.value!;
    // final imagePath = await _songController.loadAlbumArt(song.path);
    await showMediaNotification(
      title: song.title,
      artist: song.artist ?? 'Unknown Artist',
      album: song.album,
      // imagePath: imagePath as,
      isPlaying: controller.isPlaying.value,
    );
  }

  Future<void> clearNotification() async {
    await AwesomeNotifications().cancel(notificationId.hashCode);
  }

  @override
  void dispose() {
    clearNotification();
    super.dispose();
  }
}
