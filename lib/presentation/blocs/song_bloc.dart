import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/models/song_model.dart';
import '../../data/repositories/song_repository.dart';

// Events
abstract class SongEvent extends Equatable {
  const SongEvent();

  @override
  List<Object?> get props => [];
}

class LoadSongs extends SongEvent {}

class RefreshSongs extends SongEvent {}

class SearchSongs extends SongEvent {
  final String query;

  const SearchSongs(this.query);

  @override
  List<Object?> get props => [query];
}

class SortSongs extends SongEvent {
  final SortType sortType;

  const SortSongs(this.sortType);

  @override
  List<Object?> get props => [sortType];
}

class ToggleFavorite extends SongEvent {
  final String songId;

  const ToggleFavorite(this.songId);

  @override
  List<Object?> get props => [songId];
}

class LoadFavorites extends SongEvent {}

class LoadArtists extends SongEvent {}

class LoadAlbums extends SongEvent {}

// States
abstract class SongState extends Equatable {
  const SongState();

  @override
  List<Object?> get props => [];
}

class SongInitial extends SongState {}

class SongLoading extends SongState {}

class SongsLoaded extends SongState {
  final List<Song> songs;
  final List<Song> filteredSongs;
  final List<Artist> artists;
  final List<Album> albums;
  final List<Song> favorites;
  final SortType currentSortType;
  final String? searchQuery;
  final bool isLoading;

  const SongsLoaded({
    required this.songs,
    required this.filteredSongs,
    required this.artists,
    required this.albums,
    required this.favorites,
    this.currentSortType = SortType.nameAsc,
    this.searchQuery,
    this.isLoading = false,
  });

  SongsLoaded copyWith({
    List<Song>? songs,
    List<Song>? filteredSongs,
    List<Artist>? artists,
    List<Album>? albums,
    List<Song>? favorites,
    SortType? currentSortType,
    String? searchQuery,
    bool? isLoading,
  }) {
    return SongsLoaded(
      songs: songs ?? this.songs,
      filteredSongs: filteredSongs ?? this.filteredSongs,
      artists: artists ?? this.artists,
      albums: albums ?? this.albums,
      favorites: favorites ?? this.favorites,
      currentSortType: currentSortType ?? this.currentSortType,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        songs,
        filteredSongs,
        artists,
        albums,
        favorites,
        currentSortType,
        searchQuery,
        isLoading,
      ];
}

class SongError extends SongState {
  final String message;

  const SongError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class SongBloc extends Bloc<SongEvent, SongState> {
  final SongRepository _songRepository;

  SongBloc(this._songRepository) : super(SongInitial()) {
    on<LoadSongs>(_onLoadSongs);
    on<RefreshSongs>(_onRefreshSongs);
    on<SearchSongs>(_onSearchSongs);
    on<SortSongs>(_onSortSongs);
    on<ToggleFavorite>(_onToggleFavorite);
    on<LoadFavorites>(_onLoadFavorites);
    on<LoadArtists>(_onLoadArtists);
    on<LoadAlbums>(_onLoadAlbums);
  }

  Future<void> _onLoadSongs(LoadSongs event, Emitter<SongState> emit) async {
    try {
      emit(SongLoading());

      final songs = await _songRepository.getAllSongs();
      final artists = await _songRepository.getArtists();
      final albums = await _songRepository.getAlbums();
      final favorites = await _songRepository.getFavoriteSongs();

      emit(SongsLoaded(
        songs: songs,
        filteredSongs: songs,
        artists: artists,
        albums: albums,
        favorites: favorites,
      ));
    } catch (e) {
      emit(SongError('Failed to load songs: $e'));
    }
  }

  Future<void> _onRefreshSongs(RefreshSongs event, Emitter<SongState> emit) async {
    try {
      final currentState = state;
      if (currentState is SongsLoaded) {
        emit(currentState.copyWith(isLoading: true));

        final songs = await _songRepository.getAllSongs();
        final artists = await _songRepository.getArtists();
        final albums = await _songRepository.getAlbums();
        final favorites = await _songRepository.getFavoriteSongs();

        // Apply current filters
        List<Song> filteredSongs = songs;
        if (currentState.searchQuery != null && currentState.searchQuery!.isNotEmpty) {
          filteredSongs = await _songRepository.searchSongs(currentState.searchQuery!);
        }
        filteredSongs = await _songRepository.sortSongs(filteredSongs, currentState.currentSortType);

        emit(SongsLoaded(
          songs: songs,
          filteredSongs: filteredSongs,
          artists: artists,
          albums: albums,
          favorites: favorites,
          currentSortType: currentState.currentSortType,
          searchQuery: currentState.searchQuery,
          isLoading: false,
        ));
      }
    } catch (e) {
      emit(SongError('Failed to refresh songs: $e'));
    }
  }

  Future<void> _onSearchSongs(SearchSongs event, Emitter<SongState> emit) async {
    try {
      final currentState = state;
      if (currentState is SongsLoaded) {
        List<Song> filteredSongs;
        if (event.query.isEmpty) {
          filteredSongs = currentState.songs;
        } else {
          filteredSongs = await _songRepository.searchSongs(event.query);
        }
        
        filteredSongs = await _songRepository.sortSongs(filteredSongs, currentState.currentSortType);

        emit(currentState.copyWith(
          filteredSongs: filteredSongs,
          searchQuery: event.query.isEmpty ? null : event.query,
        ));
      }
    } catch (e) {
      emit(SongError('Failed to search songs: $e'));
    }
  }

  Future<void> _onSortSongs(SortSongs event, Emitter<SongState> emit) async {
    try {
      final currentState = state;
      if (currentState is SongsLoaded) {
        final sortedSongs = await _songRepository.sortSongs(currentState.filteredSongs, event.sortType);

        emit(currentState.copyWith(
          filteredSongs: sortedSongs,
          currentSortType: event.sortType,
        ));
      }
    } catch (e) {
      emit(SongError('Failed to sort songs: $e'));
    }
  }

  Future<void> _onToggleFavorite(ToggleFavorite event, Emitter<SongState> emit) async {
    try {
      final currentState = state;
      if (currentState is SongsLoaded) {
        // Update the song in the lists
        final updatedSongs = currentState.songs.map((song) {
          if (song.id == event.songId) {
            return song.copyWith(isFavorite: !song.isFavorite);
          }
          return song;
        }).toList();

        final updatedFilteredSongs = currentState.filteredSongs.map((song) {
          if (song.id == event.songId) {
            return song.copyWith(isFavorite: !song.isFavorite);
          }
          return song;
        }).toList();

        // Update favorites list
        final updatedFavorites = updatedSongs.where((song) => song.isFavorite).toList();

        // Save to repository
        await _songRepository.toggleFavorite(event.songId);

        emit(currentState.copyWith(
          songs: updatedSongs,
          filteredSongs: updatedFilteredSongs,
          favorites: updatedFavorites,
        ));
      }
    } catch (e) {
      emit(SongError('Failed to toggle favorite: $e'));
    }
  }

  Future<void> _onLoadFavorites(LoadFavorites event, Emitter<SongState> emit) async {
    try {
      final favorites = await _songRepository.getFavoriteSongs();
      final currentState = state;
      
      if (currentState is SongsLoaded) {
        emit(currentState.copyWith(favorites: favorites));
      }
    } catch (e) {
      emit(SongError('Failed to load favorites: $e'));
    }
  }

  Future<void> _onLoadArtists(LoadArtists event, Emitter<SongState> emit) async {
    try {
      final artists = await _songRepository.getArtists();
      final currentState = state;
      
      if (currentState is SongsLoaded) {
        emit(currentState.copyWith(artists: artists));
      }
    } catch (e) {
      emit(SongError('Failed to load artists: $e'));
    }
  }

  Future<void> _onLoadAlbums(LoadAlbums event, Emitter<SongState> emit) async {
    try {
      final albums = await _songRepository.getAlbums();
      final currentState = state;
      
      if (currentState is SongsLoaded) {
        emit(currentState.copyWith(albums: albums));
      }
    } catch (e) {
      emit(SongError('Failed to load albums: $e'));
    }
  }
} 