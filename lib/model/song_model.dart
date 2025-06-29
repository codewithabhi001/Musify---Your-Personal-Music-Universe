import 'dart:typed_data';

class SongModel {
  final int id;
  final String path;
  final String title;
  final String? artist;
  final String? album;
  final int? dateAdded;
  final Uint8List? albumArt;

  SongModel({
    required this.id,
    required this.path,
    required this.title,
    this.artist,
    this.album,
    this.dateAdded,
    this.albumArt,
  });
}
