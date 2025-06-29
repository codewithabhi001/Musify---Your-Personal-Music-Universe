import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:get/get.dart';
import 'package:musify/controllers/song_controller.dart';
import 'package:musify/service/notification_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/song_model.dart';

class PlayerController extends GetxController {
  final AudioPlayer _player = AudioPlayer();
  final isPlaying = false.obs;
  final currentSong = Rxn<SongModel>();
  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;
  final isShuffling = false.obs;
  final isLooping = false.obs;
  final volume = 1.0.obs;
  final isBuffering = false.obs;

  final SongController _songController = Get.find<SongController>();
  late NotificationService _notificationService;
  bool _initialized = false;
  List<int> _shuffledIndices = [];
  int _currentShuffleIndex = 0;

  StreamSubscription? _playerStateSub;

  PlayerController() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _notificationService = Get.find<NotificationService>();
      await _initializeAudio();
      await _loadSavedState();
    } catch (e) {
      debugPrint('Error initializing player: $e');
      Get.snackbar('Error', 'Failed to initialize player',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _initializeAudio() async {
    if (_initialized) return;

    try {
      await _player.setVolume(volume.value);

      _playerStateSub = _player.playerStateStream.listen((state) {
        isPlaying.value = state.playing;
        isBuffering.value =
            state.processingState == ProcessingState.buffering ||
                state.processingState == ProcessingState.loading;

        if (state.processingState == ProcessingState.completed) {
          handleSongCompletion();
        }

        _player.positionStream.first.then((p) {
          if (p.inMilliseconds <= (duration.value.inMilliseconds + 100)) {
            position.value = p;
          }
        });

        _player.durationStream.first.then((d) {
          if (d != null && d.inMilliseconds > 0) {
            duration.value = d;
          }
        });

        _notificationService.updateNotification();
      });

      _initialized = true;
    } catch (e) {
      debugPrint('Audio initialization error: $e');
      Get.snackbar('Error', 'Failed to initialize audio player',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> playSong(SongModel song) async {
    if (!_initialized) {
      await _initializeAudio();
    }

    try {
      if (!File(song.path).existsSync()) {
        Get.snackbar('Error', 'Song file not found',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      if (currentSong.value?.path == song.path && _player.playing) {
        return;
      }

      if (currentSong.value?.path == song.path && !_player.playing) {
        await resume();
        return;
      }

      isBuffering.value = true;
      await _player.stop();

      currentSong.value = song;
      position.value = Duration.zero;
      duration.value = Duration.zero;

      await _player.setAudioSource(AudioSource.uri(Uri.file(song.path)));
      await _player.play();
      isBuffering.value = false;

      if (isShuffling.value) {
        final currentIndex = _songController.songs.indexOf(song);
        if (_shuffledIndices.isEmpty && currentIndex != -1) {
          _generateShuffledIndices();
        } else if (currentIndex != -1) {
          _currentShuffleIndex = _shuffledIndices.indexOf(currentIndex);
        }
      }

      await _saveState();
      await _notificationService.updateNotification();
    } catch (e) {
      debugPrint('Play error: $e');
      Get.snackbar('Error', 'Cannot play this song',
          snackPosition: SnackPosition.BOTTOM);
      isBuffering.value = false;
    }
  }

  void _generateShuffledIndices() {
    if (_songController.songs.isEmpty) return;

    _shuffledIndices =
        List.generate(_songController.songs.length, (index) => index);
    _shuffledIndices.shuffle(Random());

    if (currentSong.value != null) {
      final currentIndex = _songController.songs.indexOf(currentSong.value!);
      if (currentIndex != -1) {
        _shuffledIndices.remove(currentIndex);
        _shuffledIndices.insert(0, currentIndex);
        _currentShuffleIndex = 0;
      }
    }
  }

  void handleSongCompletion() {
    if (isLooping.value) {
      _player.seek(Duration.zero);
      _player.play();
    } else {
      skipToNext();
    }
  }

  Future<void> play() async {
    if (currentSong.value != null) {
      await _player.play();
      _notificationService.updateNotification();
    }
  }

  Future<void> pause() async {
    if (_player.playing) {
      await _player.pause();
      _notificationService.updateNotification();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    position.value = Duration.zero;
    currentSong.value = null;
    await _notificationService.clearNotification();
  }

  Future<void> seek(Duration pos) async {
    final clampedPos = pos < Duration.zero
        ? Duration.zero
        : (pos > duration.value ? duration.value : pos);
    await _player.seek(clampedPos);
    _notificationService.updateNotification();
  }

  Future<void> skipToNext() async {
    if (_songController.songs.isEmpty) return;

    if (currentSong.value == null) {
      await playSong(_songController.songs.first);
      return;
    }

    int nextIndex;

    if (isShuffling.value) {
      if (_shuffledIndices.isEmpty) {
        _generateShuffledIndices();
      }

      _currentShuffleIndex =
          (_currentShuffleIndex + 1) % _shuffledIndices.length;

      if (_currentShuffleIndex == 0) {
        _generateShuffledIndices();
      }

      nextIndex = _shuffledIndices[_currentShuffleIndex];
    } else {
      final currentIndex = _songController.songs.indexOf(currentSong.value!);
      nextIndex = (currentIndex + 1) % _songController.songs.length;
    }

    await playSong(_songController.songs[nextIndex]);
  }

  Future<void> skipToPrevious() async {
    if (_songController.songs.isEmpty) return;

    if (currentSong.value == null) {
      await playSong(_songController.songs.last);
      return;
    }

    if (position.value.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    int prevIndex;

    if (isShuffling.value) {
      if (_shuffledIndices.isEmpty) {
        _generateShuffledIndices();
      }

      _currentShuffleIndex = _currentShuffleIndex == 0
          ? _shuffledIndices.length - 1
          : _currentShuffleIndex - 1;

      prevIndex = _shuffledIndices[_currentShuffleIndex];
    } else {
      final currentIndex = _songController.songs.indexOf(currentSong.value!);
      prevIndex = currentIndex == 0
          ? _songController.songs.length - 1
          : currentIndex - 1;
    }

    await playSong(_songController.songs[prevIndex]);
  }

  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _songController.songs.length) return;
    await playSong(_songController.songs[index]);
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> resume() async {
    if (!_player.playing && currentSong.value != null) {
      await _player.play();
      _notificationService.updateNotification();
    }
  }

  Future<void> toggleShuffle() async {
    isShuffling.value = !isShuffling.value;
    await _player.setShuffleModeEnabled(isShuffling.value);

    if (isShuffling.value) {
      _generateShuffledIndices();
    } else {
      _shuffledIndices.clear();
      _currentShuffleIndex = 0;
    }

    await _saveState();
    _notificationService.updateNotification();
  }

  Future<void> toggleLoop() async {
    isLooping.value = !isLooping.value;
    await _player.setLoopMode(isLooping.value ? LoopMode.one : LoopMode.off);
    await _saveState();
    _notificationService.updateNotification();
  }

  Future<void> setVolume(double val) async {
    volume.value = val.clamp(0.0, 1.0);
    await _player.setVolume(volume.value);
    await _saveState();
    _notificationService.updateNotification();
  }

  Future<void> shareSong() async {
    if (currentSong.value == null) return;

    try {
      final file = XFile(currentSong.value!.path);
      await Share.shareXFiles([file],
          text: 'Check out this song: ${currentSong.value!.title}');
    } catch (e) {
      debugPrint('Share error: $e');
      Get.snackbar('Error', 'Failed to share song',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isShuffling.value = prefs.getBool('isShuffling') ?? false;
      isLooping.value = prefs.getBool('isLooping') ?? false;
      volume.value = prefs.getDouble('volume') ?? 1.0;

      await _player.setShuffleModeEnabled(isShuffling.value);
      await _player.setLoopMode(isLooping.value ? LoopMode.one : LoopMode.off);
      await _player.setVolume(volume.value);

      final lastSongPath = prefs.getString('currentSong');
      if (lastSongPath != null && lastSongPath.isNotEmpty) {
        final song = _songController.songs
            .firstWhereOrNull((s) => s.path == lastSongPath);
        if (song != null) {
          await playSong(song);
        }
      }
    } catch (e) {
      debugPrint('Error loading saved state: $e');
    }
  }

  String formatDuration(Duration d) {
    if (d.inMilliseconds <= 0) return '0:00';

    final totalSeconds = d.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  double get progress {
    if (duration.value.inMilliseconds <= 0) return 0.0;
    return (position.value.inMilliseconds / duration.value.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  String get formattedPosition => formatDuration(position.value);
  String get formattedDuration => formatDuration(duration.value);

  bool get hasNext => _songController.songs.isNotEmpty;
  bool get hasPrevious => _songController.songs.isNotEmpty;

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentSong', currentSong.value?.path ?? '');
      await prefs.setBool('isShuffling', isShuffling.value);
      await prefs.setBool('isLooping', isLooping.value);
      await prefs.setDouble('volume', volume.value);
    } catch (e) {
      debugPrint('Error saving state: $e');
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _player.dispose();
    _notificationService.dispose();
    super.dispose();
  }
}
