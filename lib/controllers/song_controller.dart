import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audiotags/audiotags.dart';
import '../model/song_model.dart';

enum SortType { nameAsc, nameDesc, artist, recent }

class SongController extends GetxController {
  final songs = <SongModel>[].obs;
  final filteredSongs = <SongModel>[].obs;
  final isLoading = false.obs;
  final permissionGranted = false.obs;
  static const platform = MethodChannel('com.example.musify/audio');
  int _androidSdkVersion = 0;

  // Cache for album arts and colors
  final Map<String, Uint8List?> _albumArtCache = {};
  final Map<String, Map<String, Color>> _colorCache = {};

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _initDeviceInfo();
      await _handlePermissions();
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  Future<void> _initDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        _androidSdkVersion = info.version.sdkInt ?? 0;
      }
    } catch (e) {
      _androidSdkVersion = 0;
    }
  }

  Future<void> _handlePermissions() async {
    if (!Platform.isAndroid) {
      permissionGranted.value = true;
      await _loadSongs();
      return;
    }

    Permission permission =
        _androidSdkVersion >= 33 ? Permission.audio : Permission.storage;

    try {
      final status = await permission.status;
      if (status.isGranted) {
        permissionGranted.value = true;
        await _loadSongs();
      } else {
        final newStatus = await permission.request();
        permissionGranted.value = newStatus.isGranted;
        if (newStatus.isGranted) {
          await _loadSongs();
        }
      }
    } catch (e) {
      permissionGranted.value = false;
      debugPrint('Permission error: $e');
    }
  }

  Future<void> _loadSongs() async {
    isLoading.value = true;
    try {
      await _loadCachedSongs();
      if (Platform.isAndroid && permissionGranted.value) {
        await _fetchSongs();
      }
      filteredSongs.assignAll(songs);
      _sortSongsSync(SortType.nameAsc);
      await _cacheSongs();
      await _preloadAlbumArts();
    } catch (e) {
      debugPrint('Load songs error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadCachedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getStringList('cachedSongs') ?? [];
      final validSongs = <SongModel>[];

      for (int i = 0; i < cached.length; i++) {
        final parts = cached[i].split('|');
        if (parts.length >= 2) {
          validSongs.add(SongModel(
            id: i,
            path: parts[0],
            title: parts[1],
            artist: parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null,
            album: parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null,
            dateAdded: DateTime.now().millisecondsSinceEpoch,
            albumArt: null,
          ));
        }
      }
      songs.value = validSongs;
    } catch (e) {
      debugPrint('Load cached songs error: $e');
    }
  }

  Future<void> _fetchSongs() async {
    try {
      final nativeSongs = await platform.invokeListMethod('getSongs');
      if (nativeSongs == null) return;

      final newSongs = <SongModel>[];
      for (int i = 0; i < nativeSongs.length; i++) {
        final song = nativeSongs[i] as Map<dynamic, dynamic>;
        final path = song['path']?.toString();
        if (path == null) continue;

        newSongs.add(SongModel(
          id: i,
          path: path,
          title: song['title']?.toString() ?? path.split('/').last,
          artist: song['artist']?.toString(),
          album: song['album']?.toString(),
          dateAdded: int.tryParse(song['dateAdded']?.toString() ?? '') ??
              DateTime.now().millisecondsSinceEpoch,
          albumArt: null,
        ));
      }
      songs.value = newSongs;
    } catch (e) {
      debugPrint('Fetch songs error: $e');
    }
  }

  Future<void> _preloadAlbumArts() async {
    for (var song in songs) {
      if (!_albumArtCache.containsKey(song.path)) {
        await loadAlbumArt(song.path);
      }
    }
  }

  Future<Uint8List?> loadAlbumArt(String path) async {
    if (_albumArtCache.containsKey(path)) {
      debugPrint('Returning cached album art for: $path');
      return _albumArtCache[path];
    }

    try {
      final tag = await AudioTags.read(path);
      final bytes = tag?.pictures.firstOrNull?.bytes;
      _albumArtCache[path] = bytes;

      debugPrint('Loaded album art for $path: ${bytes?.length} bytes');

      // Cache colors if album art is available
      if (bytes != null && bytes.isNotEmpty) {
        _colorCache[path] = await _extractColors(bytes);
      } else {
        _colorCache[path] = _getDefaultColorMap();
      }

      return bytes;
    } catch (e) {
      debugPrint('Album art load error for $path: $e');
      _albumArtCache[path] = null;
      _colorCache[path] = _getDefaultColorMap();
      return null;
    }
  }

  Future<Map<String, Color>> _extractColors(Uint8List? data) async {
    if (data == null || data.isEmpty) return _getDefaultColorMap();

    try {
      // Placeholder for color extraction (already implemented in your code)
      return {
        'dominant': const Color(0xFF2A2A2A),
        'accent': const Color(0xFF3A3A3A),
      };
    } catch (e) {
      debugPrint('Color extraction error: $e');
      return _getDefaultColorMap();
    }
  }

  Map<String, Color> _getDefaultColorMap() {
    return {
      'dominant': const Color(0xFF2A2A2A),
      'accent': const Color(0xFF3A3A3A),
    };
  }

  Map<String, Color> getCachedColors(String path) {
    return _colorCache[path] ?? _getDefaultColorMap();
  }

  Future<void> _cacheSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = songs
          .map((s) => '${s.path}|${s.title}|${s.artist ?? ''}|${s.album ?? ''}')
          .toList();
      await prefs.setStringList('cachedSongs', list);
    } catch (e) {
      debugPrint('Cache songs error: $e');
    }
  }

  void searchSongs(String query) {
    final q = query.toLowerCase();
    filteredSongs.value = query.isEmpty
        ? List.from(songs)
        : songs
            .where((s) =>
                s.title.toLowerCase().contains(q) ||
                (s.artist?.toLowerCase().contains(q) ?? false))
            .toList();
    _sortSongsSync(SortType.nameAsc);
  }

  void sortSongs(SortType type) {
    _sortSongsSync(type);
  }

  void _sortSongsSync(SortType type) {
    switch (type) {
      case SortType.nameAsc:
        filteredSongs.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortType.nameDesc:
        filteredSongs.sort((a, b) => b.title.compareTo(a.title));
        break;
      case SortType.artist:
        filteredSongs
            .sort((a, b) => (a.artist ?? '').compareTo(b.artist ?? ''));
        break;
      case SortType.recent:
        filteredSongs
            .sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
        break;
    }
  }

  Future<void> refreshSongs() async {
    if (!permissionGranted.value) {
      await _handlePermissions();
      return;
    }

    isLoading.value = true;
    try {
      songs.clear();
      filteredSongs.clear();
      _albumArtCache.clear();
      _colorCache.clear();
      await _loadSongs();
    } catch (e) {
      debugPrint('Refresh songs error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  List<SongModel> getSongsByAlbum(String album) {
    return songs
        .where((song) => song.album?.toLowerCase() == album.toLowerCase())
        .toList();
  }

  List<SongModel> getSongsByArtist(String artist) {
    return songs
        .where((song) => song.artist?.toLowerCase() == artist.toLowerCase())
        .toList();
  }

  Widget getAlbumArt({SongModel? song, double? width, double? height}) {
    final s = song ?? songs.firstOrNull;
    final size = width ?? 54;

    if (s == null) return _defaultAlbumArt(size, height);

    return FutureBuilder<Uint8List?>(
      future: loadAlbumArt(s.path),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              snapshot.data!,
              width: size,
              height: height ?? size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _defaultAlbumArt(size, height),
            ),
          );
        }
        return _defaultAlbumArt(size, height);
      },
    );
  }

  Widget _defaultAlbumArt(double size, double? height) {
    return Container(
      width: size,
      height: height ?? size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade800,
      ),
      child: Icon(Icons.music_note, color: Colors.white, size: size * 0.5),
    );
  }
}
