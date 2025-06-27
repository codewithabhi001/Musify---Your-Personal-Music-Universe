import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:get/get.dart';
import 'package:musify/controllers/song_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/song_model.dart';

class PlayerController extends GetxController with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();
  final isPlaying = false.obs;
  final currentSong = Rxn<SongModel>();
  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;
  final isShuffling = false.obs;
  final isLooping = false.obs;
  final volume = 1.0.obs;

  bool _initialized = false;
  StreamSubscription? _positionSub;
  StreamSubscription? _playingSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _completionSub;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await _player.setVolume(volume.value);

      _playingSub = _player.playingStream.listen((playing) {
        isPlaying.value = playing;
      });

      _durationSub = _player.durationStream.listen((d) {
        if (d != null &&
            d.inMilliseconds > 0 &&
            d.inMilliseconds < Duration(hours: 24).inMilliseconds) {
          duration.value = d;
        } else {
          duration.value = Duration.zero;
        }
      });

      _positionSub = _player.positionStream.listen((p) {
        if (duration.value.inMilliseconds > 0 &&
            p.inMilliseconds > duration.value.inMilliseconds) {
          position.value = duration.value;
        } else {
          position.value = p;
        }
      });

      _completionSub = _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          playNext();
        }
      });

      _initialized = true;
    } catch (e) {
      debugPrint('Audio initialization error: $e');
    }
  }

  Future<void> play(SongModel song) async {
    if (!_initialized) return;
    try {
      if (!File(song.path).existsSync()) {
        Get.snackbar('Error', 'Song file not found');
        return;
      }

      if (currentSong.value?.path == song.path && _player.playing) return;

      await _player.stop();
      currentSong.value = song;
      duration.value = Duration.zero;
      position.value = Duration.zero;

      await _player.setAudioSource(AudioSource.uri(Uri.file(song.path)));

      // Wait for duration
      int attempts = 0;
      while (duration.value.inMilliseconds == 0 && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      await _player.play();
      isPlaying.value = true;
      await _saveState();
    } catch (e) {
      debugPrint('Play error: $e');
      Get.snackbar('Error', 'Cannot play this song');
    }
  }

  Future<void> playNext() async {
    final songCtrl = Get.find<SongController>();
    if (songCtrl.songs.isEmpty || currentSong.value == null) return;
    final currentIndex = songCtrl.songs.indexOf(currentSong.value!);
    final nextIndex = (currentIndex + 1) % songCtrl.songs.length;
    await play(songCtrl.songs[nextIndex]);
  }

  Future<void> playPrevious() async {
    final songCtrl = Get.find<SongController>();
    if (songCtrl.songs.isEmpty || currentSong.value == null) return;
    final currentIndex = songCtrl.songs.indexOf(currentSong.value!);
    final prevIndex =
        currentIndex == 0 ? songCtrl.songs.length - 1 : currentIndex - 1;
    await play(songCtrl.songs[prevIndex]);
  }

  Future<void> pause() async {
    await _player.pause();
    isPlaying.value = false;
  }

  Future<void> resume() async {
    await _player.play();
    isPlaying.value = true;
  }

  Future<void> stop() async {
    await _player.stop();
    isPlaying.value = false;
    position.value = Duration.zero;
    duration.value = Duration.zero;
    currentSong.value = null;

    // Release audio session focus
    final session = await AudioSession.instance;
    await session.setActive(false);
  }

  Future<void> seek(Duration pos) async {
    if (duration.value.inMilliseconds > 0 &&
        pos.inMilliseconds > duration.value.inMilliseconds) {
      pos = duration.value;
    }
    await _player.seek(pos);
    position.value = pos;
  }

  void toggleShuffle() {
    isShuffling.value = !isShuffling.value;
    _player.setShuffleModeEnabled(isShuffling.value);
    _saveState();
  }

  void toggleLoop() {
    isLooping.value = !isLooping.value;
    _player.setLoopMode(isLooping.value ? LoopMode.one : LoopMode.off);
    _saveState();
  }

  Future<void> shareSong(String path) async {
    try {
      final file = XFile(path);
      await Share.shareXFiles([file], text: 'Check out this song!');
    } catch (e) {
      debugPrint('Share error: $e');
      Get.snackbar('Error', 'Failed to share song');
    }
  }

  Future<void> setVolume(double val) async {
    volume.value = val.clamp(0.0, 1.0);
    await _player.setVolume(volume.value);
    await _saveState();
  }

  String formatDuration(Duration d) {
    if (d.inMilliseconds <= 0) return '0:00';
    final totalSeconds = d.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  double get progress {
    if (duration.value.inMilliseconds <= 0) return 0.0;
    return (position.value.inMilliseconds / duration.value.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  String get formattedPosition => formatDuration(position.value);
  String get formattedDuration => formatDuration(duration.value);

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
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      await stop(); // stop and release memory
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);

    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    _completionSub?.cancel();

    _player.dispose();

    super.onClose();
  }
}
