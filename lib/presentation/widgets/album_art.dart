import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:audiotags/audiotags.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../data/models/song_model.dart';

// Global cache for album art
final Map<String, Uint8List?> _albumArtCache = {};

Future<Uint8List?> loadAlbumArt(String filePath) async {
  try {
    if (_albumArtCache.containsKey(filePath)) {
      return _albumArtCache[filePath];
    }

    final tag = await AudioTags.read(filePath);
    final albumArt = tag?.pictures != null && tag!.pictures!.isNotEmpty
        ? tag.pictures!.first.bytes
        : null;

    _albumArtCache[filePath] = albumArt;
    return albumArt;
  } catch (e) {
    print('Error loading album art for $filePath: $e');
    _albumArtCache[filePath] = null;
    return null;
  }
}

Future<String?> extractAlbumArtPath(String filePath) async {
  try {
    if (_albumArtCache.containsKey(filePath) && _albumArtCache[filePath] != null) {
      final dir = await getTemporaryDirectory();
      final artFile = File('${dir.path}/${filePath.hashCode}.jpg');
      if (!artFile.existsSync()) {
        await artFile.writeAsBytes(_albumArtCache[filePath]!);
      }
      return artFile.path;
    }

    final tag = await AudioTags.read(filePath);
    if (tag?.pictures != null && tag!.pictures!.isNotEmpty) {
      final picture = tag.pictures!.first;
      final dir = await getTemporaryDirectory();
      final artFile = File('${dir.path}/${filePath.hashCode}.jpg');
      await artFile.writeAsBytes(picture.bytes);
      _albumArtCache[filePath] = picture.bytes;
      return artFile.path;
    }
    _albumArtCache[filePath] = null;
    return null;
  } catch (e) {
    print('Error extracting album art path for $filePath: $e');
    _albumArtCache[filePath] = null;
    return null;
  }
}

Future<void> extractAndSaveAlbumArt(List<Song> songs) async {
  for (var song in songs) {
    if (song.albumArtPath == null || song.albumArtPath!.isEmpty) {
      final albumArtPath = await extractAlbumArtPath(song.path);
      if (albumArtPath != null) {
        song = song.copyWith(albumArtPath: albumArtPath);
      }
    }
  }
}

class AlbumArtWidget extends StatefulWidget {
  final Song song;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool useFilePath;

  const AlbumArtWidget({
    super.key,
    required this.song,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.useFilePath = false,
  });

  @override
  _AlbumArtWidgetState createState() => _AlbumArtWidgetState();
}

class _AlbumArtWidgetState extends State<AlbumArtWidget> {
  late Future<dynamic> _albumArtFuture;

  @override
  void initState() {
    super.initState();
    _initializeFuture();
  }

  @override
  void didUpdateWidget(AlbumArtWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song.path != widget.song.path) {
      _initializeFuture();
    }
  }

  void _initializeFuture() {
    _albumArtFuture = widget.useFilePath
        ? extractAlbumArtPath(widget.song.path)
        : loadAlbumArt(widget.song.path);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.width ?? 54.0;
    return SizedBox(
      width: size,
      height: widget.height ?? size,
      child: FutureBuilder<dynamic>(
        future: _albumArtFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: SizedBox(
                width: size,
                height: widget.height ?? size,
                child: widget.useFilePath
                    ? Image.file(
                        File(snapshot.data! as String),
                        width: size,
                        height: widget.height ?? size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildFallback(size),
                      )
                    : Image.memory(
                        snapshot.data! as Uint8List,
                        width: size,
                        height: widget.height ?? size,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildFallback(size),
                      ),
              ),
            );
          }
          return _buildFallback(size);
        },
      ),
    );
  }

  Widget _buildFallback(double size) {
    return Container(
      width: size,
      height: widget.height ?? size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: Colors.grey.shade800,
      ),
      child: Icon(
        Icons.music_note,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}