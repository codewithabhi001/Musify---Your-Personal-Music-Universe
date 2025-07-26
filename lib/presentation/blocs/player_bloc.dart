import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/song_model.dart';
import '../../data/repositories/audio_repository.dart';

// Events
abstract class PlayerEvent extends Equatable {
  const PlayerEvent();

  @override
  List<Object?> get props => [];
}

class InitializePlayer extends PlayerEvent {}

class PlaySong extends PlayerEvent {
  final Song song;
  final List<Song>? playlist;
  final int? initialIndex;

  const PlaySong(this.song, {this.playlist, this.initialIndex});

  @override
  List<Object?> get props => [song, playlist, initialIndex];
}

class PlayPlaylist extends PlayerEvent {
  final List<Song> playlist;
  final int initialIndex;

  const PlayPlaylist(this.playlist, this.initialIndex);

  @override
  List<Object?> get props => [playlist, initialIndex];
}

class Pause extends PlayerEvent {}

class Resume extends PlayerEvent {}

class Stop extends PlayerEvent {}

class SeekTo extends PlayerEvent {
  final Duration position;

  const SeekTo(this.position);

  @override
  List<Object?> get props => [position];
}

class SkipToNext extends PlayerEvent {}

class SkipToPrevious extends PlayerEvent {}

class SetVolume extends PlayerEvent {
  final double volume;

  const SetVolume(this.volume);

  @override
  List<Object?> get props => [volume];
}

// Internal events for stream updates
class _UpdatePosition extends PlayerEvent {
  final Duration position;
  const _UpdatePosition(this.position);

  @override
  List<Object?> get props => [position];
}

class _UpdateDuration extends PlayerEvent {
  final Duration? duration;
  const _UpdateDuration(this.duration);

  @override
  List<Object?> get props => [duration];
}

class _UpdatePlaybackState extends PlayerEvent {
  final PlaybackState playbackState;
  const _UpdatePlaybackState(this.playbackState);

  @override
  List<Object?> get props => [playbackState];
}

class _UpdateCurrentSong extends PlayerEvent {
  final Song? song;
  const _UpdateCurrentSong(this.song);

  @override
  List<Object?> get props => [song];
}

// States
abstract class PlayerState extends Equatable {
  const PlayerState();

  @override
  List<Object?> get props => [];
}

class PlayerInitial extends PlayerState {}

class PlayerLoading extends PlayerState {}

class PlayerReady extends PlayerState {
  final Song? currentSong;
  final PlaybackState playbackState;
  final Duration position;
  final Duration? duration;
  final List<Song> playlist;
  final int currentIndex;
  final double volume;

  const PlayerReady({
    this.currentSong,
    this.playbackState = PlaybackState.stopped,
    this.position = Duration.zero,
    this.duration,
    this.playlist = const [],
    this.currentIndex = 0,
    this.volume = 1.0,
  });

  PlayerReady copyWith({
    Song? currentSong,
    PlaybackState? playbackState,
    Duration? position,
    Duration? duration,
    List<Song>? playlist,
    int? currentIndex,
    double? volume,
  }) {
    return PlayerReady(
      currentSong: currentSong ?? this.currentSong,
      playbackState: playbackState ?? this.playbackState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      volume: volume ?? this.volume,
    );
  }

  @override
  List<Object?> get props => [
        currentSong,
        playbackState,
        position,
        duration,
        playlist,
        currentIndex,
        volume,
      ];
}

class PlayerError extends PlayerState {
  final String message;

  const PlayerError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final AudioRepository _audioRepository;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlaybackState>? _playbackStateSubscription;
  StreamSubscription<Song?>? _currentSongSubscription;
  bool _isInitialized = false;

  PlayerBloc(this._audioRepository) : super(PlayerInitial()) {
    on<InitializePlayer>(_onInitializePlayer);
    on<PlaySong>(_onPlaySong);
    on<PlayPlaylist>(_onPlayPlaylist);
    on<Pause>(_onPause);
    on<Resume>(_onResume);
    on<Stop>(_onStop);
    on<SeekTo>(_onSeekTo);
    on<SkipToNext>(_onSkipToNext);
    on<SkipToPrevious>(_onSkipToPrevious);
    on<SetVolume>(_onSetVolume);
    on<_UpdatePosition>(_onUpdatePosition);
    on<_UpdateDuration>(_onUpdateDuration);
    on<_UpdatePlaybackState>(_onUpdatePlaybackState);
    on<_UpdateCurrentSong>(_onUpdateCurrentSong);
    
    // Initialize player automatically
    add(InitializePlayer());
  }

  Future<void> _onInitializePlayer(
      InitializePlayer event, Emitter<PlayerState> emit) async {
    if (_isInitialized) return;
    emit(PlayerLoading());
    try {
      await _audioRepository.initialize();
      _setupStreamListeners();
      _isInitialized = true;
      emit(PlayerReady());
    } catch (e) {
      emit(PlayerError('Failed to initialize player: $e'));
    }
  }

  void _setupStreamListeners() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playbackStateSubscription?.cancel();
    _currentSongSubscription?.cancel();

    _positionSubscription = _audioRepository.positionStream.listen((position) {
      if (!isClosed && state is PlayerReady) {
        add(_UpdatePosition(position));
      }
    });

    _durationSubscription = _audioRepository.durationStream.listen((duration) {
      if (!isClosed && state is PlayerReady) {
        add(_UpdateDuration(duration));
      }
    });

    _playbackStateSubscription =
        _audioRepository.playbackStateStream.listen((playbackState) {
      if (!isClosed && state is PlayerReady) {
        add(_UpdatePlaybackState(playbackState));
      }
    });

    _currentSongSubscription = _audioRepository.currentSongStream.listen((song) {
      if (!isClosed && state is PlayerReady) {
        add(_UpdateCurrentSong(song));
      }
    });
  }

  Future<void> _onPlaySong(PlaySong event, Emitter<PlayerState> emit) async {
    try {
      if (!_isInitialized) {
        await _audioRepository.initialize();
        _setupStreamListeners();
        _isInitialized = true;
      }

      final currentState = state is PlayerReady ? state as PlayerReady : null;
      List<Song> playlist = event.playlist ?? currentState?.playlist ?? [event.song];
      int newIndex = event.initialIndex ??
          playlist.indexWhere((s) => s.id == event.song.id).clamp(0, playlist.length - 1);

      emit(PlayerReady(
        currentSong: event.song,
        playbackState: PlaybackState.loading,
        playlist: playlist,
        currentIndex: newIndex,
        position: Duration.zero,
        duration: currentState?.duration,
        volume: currentState?.volume ?? 1.0,
      ));

      await _audioRepository.setPlaylist(playlist, newIndex);
      await _audioRepository.playSong(event.song);
    } catch (e) {
      emit(PlayerError('Failed to play song: $e'));
    }
  }

  Future<void> _onPlayPlaylist(
      PlayPlaylist event, Emitter<PlayerState> emit) async {
    if (event.playlist.isEmpty) {
      emit(PlayerError('Playlist is empty'));
      return;
    }

    try {
      if (!_isInitialized) {
        await _audioRepository.initialize();
        _setupStreamListeners();
        _isInitialized = true;
      }

      final newIndex = event.initialIndex.clamp(0, event.playlist.length - 1);
      final song = event.playlist[newIndex];

      emit(PlayerReady(
        currentSong: song,
        playbackState: PlaybackState.loading,
        playlist: event.playlist,
        currentIndex: newIndex,
        position: Duration.zero,
        volume: (state is PlayerReady) ? (state as PlayerReady).volume : 1.0,
      ));

      await _audioRepository.setPlaylist(event.playlist, newIndex);
      await _audioRepository.playSong(song);
    } catch (e) {
      emit(PlayerError('Failed to play playlist: $e'));
    }
  }

  Future<void> _onPause(Pause event, Emitter<PlayerState> emit) async {
    if (state is! PlayerReady) {
      return;
    }
    
    final currentState = state as PlayerReady;
    if (currentState.playbackState != PlaybackState.playing) {
      print('PlayerBloc: Cannot pause - not currently playing (state: ${currentState.playbackState})');
      return;
    }
    
    try {
      print('PlayerBloc: Pausing playback...');
      // Emit paused state immediately for UI responsiveness
      emit(currentState.copyWith(playbackState: PlaybackState.paused));
      await _audioRepository.pause();
      print('PlayerBloc: Paused successfully');
    } catch (e) {
      print('PlayerBloc: Failed to pause: $e');
      emit(PlayerError('Failed to pause: $e'));
    }
  }

  Future<void> _onResume(Resume event, Emitter<PlayerState> emit) async {
    if (state is! PlayerReady) {
      return;
    }
    
    final currentState = state as PlayerReady;
    if (currentState.playbackState != PlaybackState.paused && currentState.playbackState != PlaybackState.stopped) {
      print('PlayerBloc: Cannot resume - not paused or stopped (state: ${currentState.playbackState})');
      return;
    }
    
    try {
      print('PlayerBloc: Resuming playback...');
      // Emit playing state immediately for UI responsiveness
      emit(currentState.copyWith(playbackState: PlaybackState.playing));
      await _audioRepository.resume();
      print('PlayerBloc: Resumed successfully');
    } catch (e) {
      print('PlayerBloc: Failed to resume: $e');
      emit(PlayerError('Failed to resume: $e'));
    }
  }

  Future<void> _onStop(Stop event, Emitter<PlayerState> emit) async {
    if (state is! PlayerReady) return;
    try {
      emit((state as PlayerReady).copyWith(
        playbackState: PlaybackState.stopped,
        position: Duration.zero,
      ));
      await _audioRepository.stop();
    } catch (e) {
      emit(PlayerError('Failed to stop: $e'));
    }
  }

  Future<void> _onSeekTo(SeekTo event, Emitter<PlayerState> emit) async {
    if (state is! PlayerReady) return;
    try {
      emit((state as PlayerReady).copyWith(position: event.position));
      await _audioRepository.seekTo(event.position);
    } catch (e) {
      emit(PlayerError('Failed to seek: $e'));
    }
  }

  Future<void> _onSkipToNext(SkipToNext event, Emitter<PlayerState> emit) async {
    if (state is! PlayerReady || (state as PlayerReady).playlist.isEmpty) return;
    try {
      final ready = state as PlayerReady;
      final newIndex = (ready.currentIndex + 1) % ready.playlist.length;
      final nextSong = ready.playlist[newIndex];

      emit(ready.copyWith(
        currentIndex: newIndex,
        currentSong: nextSong,
        playbackState: PlaybackState.loading,
        position: Duration.zero,
      ));
      await _audioRepository.skipToNext();
    } catch (e) {
      emit(PlayerError('Failed to skip to next: $e'));
    }
  }

  Future<void> _onSkipToPrevious(SkipToPrevious event, Emitter<PlayerState> emit) async {
    if (state is! PlayerReady || (state as PlayerReady).playlist.isEmpty) return;
    try {
      final ready = state as PlayerReady;
      final newIndex =
          (ready.currentIndex - 1 + ready.playlist.length) % ready.playlist.length;
      final prevSong = ready.playlist[newIndex];

      emit(ready.copyWith(
        currentIndex: newIndex,
        currentSong: prevSong,
        playbackState: PlaybackState.loading,
        position: Duration.zero,
      ));
      await _audioRepository.skipToPrevious();
    } catch (e) {
      emit(PlayerError('Failed to skip to previous: $e'));
    }
  }

  Future<void> _onSetVolume(SetVolume event, Emitter<PlayerState> emit) async {
    if (state is! PlayerReady) return;
    try {
      final volume = event.volume.clamp(0.0, 1.0);
      emit((state as PlayerReady).copyWith(volume: volume));
      await _audioRepository.setVolume(volume);
    } catch (e) {
      emit(PlayerError('Failed to set volume: $e'));
    }
  }

  void _onUpdatePosition(_UpdatePosition event, Emitter<PlayerState> emit) {
    if (state is PlayerReady && (state as PlayerReady).position != event.position) {
      emit((state as PlayerReady).copyWith(position: event.position));
    }
  }

  void _onUpdateDuration(_UpdateDuration event, Emitter<PlayerState> emit) {
    if (state is PlayerReady && (state as PlayerReady).duration != event.duration) {
      emit((state as PlayerReady).copyWith(duration: event.duration));
    }
  }

  void _onUpdatePlaybackState(_UpdatePlaybackState event, Emitter<PlayerState> emit) {
    if (state is PlayerReady && (state as PlayerReady).playbackState != event.playbackState) {
      emit((state as PlayerReady).copyWith(playbackState: event.playbackState));
    }
  }

  void _onUpdateCurrentSong(_UpdateCurrentSong event, Emitter<PlayerState> emit) {
    if (state is PlayerReady && (state as PlayerReady).currentSong != event.song) {
      emit((state as PlayerReady).copyWith(currentSong: event.song));
    }
  }

  @override
  Future<void> close() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playbackStateSubscription?.cancel();
    _currentSongSubscription?.cancel();
    _audioRepository.dispose();
    return super.close();
  }
}