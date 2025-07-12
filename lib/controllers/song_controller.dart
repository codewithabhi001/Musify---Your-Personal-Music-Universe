import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../model/song_model.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class SongController extends GetxController {
  final songs = <SongModel>[].obs;
  final filteredSongs = <SongModel>[].obs;
  final isLoading = false.obs;
  final permissionGranted = false.obs;
  static const platform = MethodChannel('com.example.musify/audio');
  int _androidSdkVersion = 0;
  bool _initialized = false;
  final RxList allSongs = [].obs;

  // Debounced search
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _initAudio();
    await _loadPreferences();
    if (Platform.isAndroid) {
      await _checkAndRequestPermissions();
    } else {
      await _loadSongs();
    }
  }

  /// Reset filtered songs back to original songs list
  void resetSearch() {
    filteredSongs.value = List<SongModel>.from(songs);
  }

  Future<void> _initAudio() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = await DeviceInfoPlugin().androidInfo;
        _androidSdkVersion = deviceInfo.version.sdkInt;
      }
      _initialized = true;
    } catch (e) {
      debugPrint('Audio initialization error: $e');
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // No specific preferences to load here, can be extended if needed
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    if (!Platform.isAndroid) {
      permissionGranted.value = true;
      return;
    }
    try {
      PermissionStatus status;
      if (_androidSdkVersion >= 33) {
        status = await Permission.audio.status;
        if (status.isGranted) {
          permissionGranted.value = true;
          await _loadSongs();
          return;
        }
        status = await Permission.audio.request();
      } else {
        status = await Permission.storage.status;
        if (status.isGranted) {
          permissionGranted.value = true;
          await _loadSongs();
          return;
        }
        status = await Permission.storage.request();
      }

      if (status.isGranted) {
        permissionGranted.value = true;
        await _loadSongs();
      } else {
        permissionGranted.value = false;
        _showPermissionDialog(status);
      }
    } catch (e) {
      debugPrint('Permission check error: $e');
      permissionGranted.value = false;
      // Don't show error dialog for permission errors, just log them
    }
  }

  void _showPermissionDialog(PermissionStatus status) {
    Get.dialog(
      AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          status.isPermanentlyDenied
              ? 'Please enable storage/audio permission in app settings to load your music.'
              : 'This app needs storage/audio permission to access your music files.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              if (status.isPermanentlyDenied) {
                await openAppSettings();
              } else {
                await _checkAndRequestPermissions();
              }
            },
            child: Text(status.isPermanentlyDenied ? 'Settings' : 'Allow'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _loadSongs() async {
    if (!_initialized) return;
    isLoading.value = true;
    try {
      await _loadCachedSongs();
      if (Platform.isAndroid && permissionGranted.value) {
        await _fetchSongsFromDevice();
      }
      _updateFilteredLists();
      sortSongs(SortType.nameAsc);
      await _cacheSongs();
    } catch (e) {
      debugPrint('Error loading songs: $e');
      if (permissionGranted.value) {
        Get.snackbar('Error', 'Failed to load songs');
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Use compute for loading cached songs if the list is large
  Future<void> _loadCachedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedSongs = prefs.getStringList('cachedSongs') ?? [];
      if (cachedSongs.isNotEmpty) {
        // Use compute for parsing if list is large
        final validSongs = cachedSongs.length > 200
            ? await compute(_parseCachedSongsIsolate, cachedSongs)
            : _parseCachedSongsIsolate(cachedSongs);
        songs.value = validSongs;
      }
    } catch (e) {
      debugPrint('Error loading cached songs: $e');
    }
  }

  static List<SongModel> _parseCachedSongsIsolate(List<String> cachedSongs) {
    final validSongs = <SongModel>[];
    for (int i = 0; i < cachedSongs.length; i++) {
      final parts = cachedSongs[i].split('|');
      if (parts.length >= 2 && File(parts[0]).existsSync()) {
        validSongs.add(SongModel(
          title: parts[1],
          artist: parts.length > 2 && parts[2].isNotEmpty ? parts[2] : null,
          path: parts[0],
          id: i,
          dateAdded: DateTime.now().millisecondsSinceEpoch,
          albumArt: null,
          album: parts.length > 3 && parts[3].isNotEmpty ? parts[3] : null,
        ));
      }
    }
    return validSongs;
  }

  // Use compute for device fetch if list is large
  Future<void> _fetchSongsFromDevice() async {
    try {
      final List<dynamic>? nativeSongs =
          await platform.invokeListMethod('getSongs');
      if (nativeSongs != null && nativeSongs.isNotEmpty) {
        final newSongs = nativeSongs.length > 200
            ? await compute(_parseNativeSongsIsolate, nativeSongs)
            : _parseNativeSongsIsolate(nativeSongs);
        if (newSongs.isNotEmpty) {
          songs.value = newSongs;
        }
      }
    } catch (e) {
      debugPrint('Error fetching songs from device: $e');
    }
  }

  static List<SongModel> _parseNativeSongsIsolate(List<dynamic> nativeSongs) {
    final newSongs = <SongModel>[];
    for (var i = 0; i < nativeSongs.length; i++) {
      final song = nativeSongs[i] as Map<dynamic, dynamic>;
      final path = song['path']?.toString();
      if (path != null && File(path).existsSync()) {
        newSongs.add(SongModel(
          title: song['title']?.toString() ?? path.substringAfterLast('/'),
          artist: song['artist']?.toString(),
          path: path,
          id: i,
          dateAdded: int.tryParse(song['dateAdded']?.toString() ?? '') ??
              DateTime.now().millisecondsSinceEpoch,
          albumArt: null,
          album: song['album']?.toString(),
        ));
      }
    }
    return newSongs;
  }

  Future<void> _cacheSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cache = songs
          .map((s) => '${s.path}|${s.title}|${s.artist ?? ''}|${s.album ?? ''}')
          .toList();
      await prefs.setStringList('cachedSongs', cache);
    } catch (e) {
      debugPrint('Error caching songs: $e');
    }
  }

  void _updateFilteredLists() {
    filteredSongs.value = List<SongModel>.from(songs);
  }

  void searchSongs(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      final lowerQuery = query.toLowerCase();
      final List<SongModel> baseList = List<SongModel>.from(songs);
      if (query.isEmpty) {
        filteredSongs.value = baseList;
        sortSongs(SortType.nameAsc);
        return;
      }
      // Use compute for heavy filtering
      final result = await compute(
          _filterSongsIsolate, {'songs': baseList, 'query': lowerQuery});
      filteredSongs.value = result;
      sortSongs(SortType.nameAsc);
    });
  }

  static List<SongModel> _filterSongsIsolate(Map<String, dynamic> args) {
    final List<SongModel> songs = List<SongModel>.from(args['songs']);
    final String query = args['query'];
    return songs
        .where((song) =>
            song.title.toLowerCase().contains(query) ||
            (song.artist?.toLowerCase().contains(query) ?? false))
        .toList();
  }

  Future<void> sortSongs(SortType type) async {
    final List<SongModel> baseList = List<SongModel>.from(filteredSongs);
    final sorted =
        await compute(_sortSongsIsolate, {'songs': baseList, 'type': type});
    filteredSongs.value = sorted;
  }

  static List<SongModel> _sortSongsIsolate(Map<String, dynamic> args) {
    final List<SongModel> list = List<SongModel>.from(args['songs']);
    final SortType type = args['type'];
    list.sort((a, b) {
      switch (type) {
        case SortType.nameAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case SortType.nameDesc:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
        case SortType.artist:
          return (a.artist ?? 'Unknown')
              .toLowerCase()
              .compareTo((b.artist ?? 'Unknown').toLowerCase());
        case SortType.recent:
          return (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0);
      }
    });
    return list;
  }

  Future<void> refreshSongs() async {
    if (!permissionGranted.value) {
      await _checkAndRequestPermissions();
      return;
    }
    isLoading.value = true;
    songs.clear();
    filteredSongs.clear();
    await _loadSongs();
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
}
