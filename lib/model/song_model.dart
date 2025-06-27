import 'dart:typed_data';

enum SortType { nameAsc, nameDesc, artist, recent }

enum PlaybackState { playing, paused, stopped }

class SongModel {
  final String title;
  final String? artist;
  final String path;
  final int id;
  final int? dateAdded;
  final Uint8List? albumArt;
  final String? album;

  SongModel({
    required this.title,
    this.artist,
    required this.path,
    required this.id,
    this.dateAdded,
    this.albumArt,
    this.album,
  });
}

extension StringExtension on String {
  String substringAfterLast(String delimiter) {
    final index = lastIndexOf(delimiter);
    return index == -1 ? this : substring(index + 1);
  }

  String get capitalizeFirst =>
      isNotEmpty ? '${this[0].toUpperCase()}${substring(1)}' : this;
}
