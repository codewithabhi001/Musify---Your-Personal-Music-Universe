import 'package:equatable/equatable.dart';

class Song extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String path;
  final Duration duration;
  final String? albumArtPath;
  final int? trackNumber;
  final int? year;
  final String? genre;
  final bool isFavorite;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.duration,
    this.albumArtPath,
    this.trackNumber,
    this.year,
    this.genre,
    this.isFavorite = false,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    String? path,
    Duration? duration,
    String? albumArtPath,
    int? trackNumber,
    int? year,
    String? genre,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      albumArtPath: albumArtPath ?? this.albumArtPath,
      trackNumber: trackNumber ?? this.trackNumber,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'path': path,
      'duration': duration.inMilliseconds,
      'albumArtPath': albumArtPath,
      'trackNumber': trackNumber,
      'year': year,
      'genre': genre,
      'isFavorite': isFavorite,
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      album: json['album'] as String,
      path: json['path'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      albumArtPath: json['albumArtPath'] as String?,
      trackNumber: json['trackNumber'] as int?,
      year: json['year'] as int?,
      genre: json['genre'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        album,
        path,
        duration,
        albumArtPath,
        trackNumber,
        year,
        genre,
        isFavorite,
      ];
}

class Artist extends Equatable {
  final String name;
  final List<Song> songs;
  final String? imagePath;

  const Artist({
    required this.name,
    required this.songs,
    this.imagePath,
  });

  int get songCount => songs.length;

  Duration get totalDuration {
    return songs.fold(
      Duration.zero,
      (total, song) => total + song.duration,
    );
  }

  @override
  List<Object?> get props => [name, songs, imagePath];
}

class Album extends Equatable {
  final String name;
  final String artist;
  final List<Song> songs;
  final String? coverPath;
  final int? year;

  const Album({
    required this.name,
    required this.artist,
    required this.songs,
    this.coverPath,
    this.year,
  });

  int get songCount => songs.length;

  Duration get totalDuration {
    return songs.fold(
      Duration.zero,
      (total, song) => total + song.duration,
    );
  }

  @override
  List<Object?> get props => [name, artist, songs, coverPath, year];
}

enum SortType {
  nameAsc,
  nameDesc,
  artist,
  album,
  duration,
  recent,
  favorite,
}

enum PlaybackState {
  stopped,
  playing,
  paused,
  loading,
  error,
} 