import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/song_model.dart';
import '../../core/constants/app_constants.dart';

abstract class AudioRepository {
  Future<void> initialize();
  Future<void> playSong(Song song);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> seekTo(Duration position);
  Future<void> skipToNext();
  Future<void> skipToPrevious();
  Future<void> setVolume(double volume);
  Future<void> setPlaylist(List<Song> playlist, int initialIndex);
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<PlaybackState> get playbackStateStream;
  Stream<Song?> get currentSongStream;
  Song? get currentSong;
  PlaybackState get currentPlaybackState;
  Duration get currentPosition;
  Duration? get currentDuration;
  List<Song> get currentPlaylist;
  int get currentIndex;
  void dispose();
}

class AudioRepositoryImpl implements AudioRepository {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SharedPreferences _prefs;
  
  Song? _currentSong;
  List<Song> _playlist = [];
  int _currentIndex = 0;
  PlaybackState _playbackState = PlaybackState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration? _currentDuration;

  // Stream controllers for better control
  final StreamController<Song?> _currentSongController = StreamController<Song?>.broadcast();
  final StreamController<PlaybackState> _playbackStateController = StreamController<PlaybackState>.broadcast();

  AudioRepositoryImpl(this._prefs);

  @override
  Future<void> initialize() async {
    print('AudioRepository: Initializing...');
    
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      print('AudioRepository: Player state changed - ${state.processingState}');
      _updatePlaybackState(state);
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      _currentDuration = duration;
    });

    // Listen to completion and auto-play next
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        print('AudioRepository: Song completed, checking for auto-play...');
        // Auto-play next song if available
        if (_playlist.isNotEmpty && _currentIndex < _playlist.length - 1) {
          print('AudioRepository: Auto-playing next song...');
          skipToNext();
        } else {
          print('AudioRepository: No more songs to auto-play');
        }
      }
    });
    
    print('AudioRepository: Initialized successfully');
  }

  @override
  Future<void> playSong(Song song) async {
    try {
      print('AudioRepository: Playing song - ${song.title}');
      _currentSong = song;
      _currentSongController.add(song);
      
      await _audioPlayer.setFilePath(song.path);
      await _audioPlayer.seek(Duration.zero); // Always start from beginning
      await _audioPlayer.play();
      await _saveLastPlayedSong(song);
      print('AudioRepository: Song started playing successfully');
    } catch (e) {
      print('AudioRepository: Error playing song: $e');
      _playbackState = PlaybackState.error;
      _playbackStateController.add(_playbackState);
    }
  }

  @override
  Future<void> pause() async {
    try {
      print('AudioRepository: Pausing...');
      await _audioPlayer.pause();
      _playbackState = PlaybackState.paused;
      _playbackStateController.add(_playbackState);
      print('AudioRepository: Paused successfully');
    } catch (e) {
      print('AudioRepository: Error pausing: $e');
    }
  }

  @override
  Future<void> resume() async {
    try {
      print('AudioRepository: Resuming...');
      
      // Check if we have a song loaded
      if (_currentSong == null) {
        print('AudioRepository: No song loaded, cannot resume');
        return;
      }
      
      // Check current player state
      final playerState = _audioPlayer.playerState;
      print('AudioRepository: Current player state - ${playerState.processingState}, playing: ${playerState.playing}');
      
      if (playerState.processingState == ProcessingState.idle) {
        print('AudioRepository: Player is idle, reloading song...');
        await _audioPlayer.setFilePath(_currentSong!.path);
      }
      
      await _audioPlayer.play();
      _playbackState = PlaybackState.playing;
      _playbackStateController.add(_playbackState);
      print('AudioRepository: Resumed successfully');
    } catch (e) {
      print('AudioRepository: Error resuming: $e');
      _playbackState = PlaybackState.error;
      _playbackStateController.add(_playbackState);
    }
  }

  @override
  Future<void> stop() async {
    try {
      print('AudioRepository: Stopping...');
      await _audioPlayer.stop();
      _playbackState = PlaybackState.stopped;
      _playbackStateController.add(_playbackState);
      _currentPosition = Duration.zero;
      print('AudioRepository: Stopped successfully');
    } catch (e) {
      print('AudioRepository: Error stopping: $e');
    }
  }

  @override
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      _currentPosition = position;
    } catch (e) {
      print('AudioRepository: Error seeking: $e');
    }
  }

  @override
  Future<void> skipToNext() async {
    print('AudioRepository: Skipping to next song...');
    print('AudioRepository: Current index: $_currentIndex, Playlist length: ${_playlist.length}');
    
    if (_playlist.isNotEmpty && _currentIndex < _playlist.length - 1) {
      _currentIndex++;
      final nextSong = _playlist[_currentIndex];
      print('AudioRepository: Playing next song - ${nextSong.title} at index $_currentIndex');
      await playSong(nextSong);
    } else {
      print('AudioRepository: Cannot skip to next - no more songs or playlist empty');
    }
  }

  @override
  Future<void> skipToPrevious() async {
    print('AudioRepository: Skipping to previous song...');
    print('AudioRepository: Current index: $_currentIndex, Playlist length: ${_playlist.length}');
    
    if (_playlist.isNotEmpty && _currentIndex > 0) {
      _currentIndex--;
      final prevSong = _playlist[_currentIndex];
      print('AudioRepository: Playing previous song - ${prevSong.title} at index $_currentIndex');
      await playSong(prevSong);
    } else {
      print('AudioRepository: Cannot skip to previous - at first song or playlist empty');
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume);
    } catch (e) {
      print('AudioRepository: Error setting volume: $e');
    }
  }

  @override
  Future<void> setPlaylist(List<Song> playlist, int initialIndex) async {
    print('AudioRepository: Setting playlist with ${playlist.length} songs, initial index: $initialIndex');
    _playlist = playlist;
    _currentIndex = initialIndex;
    
    // Only play the song if it's different from current song or if no song is playing
    if (playlist.isNotEmpty && initialIndex < playlist.length) {
      final songToPlay = playlist[initialIndex];
      if (_currentSong?.id != songToPlay.id) {
        print('AudioRepository: Playing initial song from playlist - ${songToPlay.title}');
        await playSong(songToPlay);
      } else {
        print('AudioRepository: Song already playing, not changing');
      }
    }
  }

  @override
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  @override
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  @override
  Stream<PlaybackState> get playbackStateStream => _playbackStateController.stream;

  @override
  Stream<Song?> get currentSongStream => _currentSongController.stream;

  @override
  Song? get currentSong => _currentSong;

  @override
  PlaybackState get currentPlaybackState => _playbackState;

  @override
  Duration get currentPosition => _currentPosition;

  @override
  Duration? get currentDuration => _currentDuration;

  @override
  List<Song> get currentPlaylist => _playlist;

  @override
  int get currentIndex => _currentIndex;

  void _updatePlaybackState(PlayerState state) {
    final newPlaybackState = _mapPlayerStateToPlaybackState(state);
    if (_playbackState != newPlaybackState) {
      _playbackState = newPlaybackState;
      _playbackStateController.add(_playbackState);
      print('AudioRepository: Playback state updated to: $_playbackState');
    }
  }

  PlaybackState _mapPlayerStateToPlaybackState(PlayerState state) {
    print('AudioRepository: Mapping player state - ${state.processingState}, playing: ${state.playing}');
    
    switch (state.processingState) {
      case ProcessingState.idle:
        return PlaybackState.stopped;
      case ProcessingState.loading:
        return PlaybackState.loading;
      case ProcessingState.buffering:
        return state.playing ? PlaybackState.playing : PlaybackState.paused;
      case ProcessingState.ready:
        // Key fix: properly handle ready state
        if (state.playing) {
          return PlaybackState.playing;
        } else {
          // If not playing but ready, it's paused (not stopped)
          return _currentSong != null ? PlaybackState.paused : PlaybackState.stopped;
        }
      case ProcessingState.completed:
        return PlaybackState.stopped;
    }
  }

  Future<void> _saveLastPlayedSong(Song song) async {
    try {
      await _prefs.setString(AppConstants.lastPlayedSongKey, song.id);
    } catch (e) {
      print('AudioRepository: Error saving last played song: $e');
    }
  }

  @override
  void dispose() {
    print('AudioRepository: Disposing...');
    _currentSongController.close();
    _playbackStateController.close();
    _audioPlayer.dispose();
  }
} 