import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:audiotags/audiotags.dart';
import '../model/song_model.dart';

class SongController extends GetxController {
  final songs = <SongModel>[].obs;
  final filteredSongs = <SongModel>[].obs;
  final isLoading = false.obs;
  final permissionGranted = false.obs;
  static const platform = MethodChannel('com.example.musify/audio');
  int _androidSdkVersion = 0;
  bool _initialized = false;

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
      PermissionStatus status = _androidSdkVersion >= 33
          ? await Permission.audio.status
          : await Permission.storage.status;
      if (status.isGranted) {
        permissionGranted.value = true;
        await _loadSongs();
        return;
      }
      status = _androidSdkVersion >= 33
          ? await Permission.audio.request()
          : await Permission.storage.request();
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

  Future<void> _loadCachedSongs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedSongs = prefs.getStringList('cachedSongs') ?? [];
      if (cachedSongs.isNotEmpty) {
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
        songs.value = validSongs;
      }
    } catch (e) {
      debugPrint('Error loading cached songs: $e');
    }
  }

  Future<void> _fetchSongsFromDevice() async {
    try {
      final List<dynamic>? nativeSongs =
          await platform.invokeListMethod('getSongs');
      if (nativeSongs != null && nativeSongs.isNotEmpty) {
        final newSongs = <SongModel>[];
        for (var i = 0; i < nativeSongs.length; i++) {
          final song = nativeSongs[i] as Map<dynamic, dynamic>;
          final path = song['path']?.toString();
          if (path != null && File(path).existsSync()) {
            final albumArt = await _loadAlbumArt(path);
            newSongs.add(SongModel(
              title: song['title']?.toString() ?? path.substringAfterLast('/'),
              artist: song['artist']?.toString(),
              path: path,
              id: i,
              dateAdded: int.tryParse(song['dateAdded']?.toString() ?? '') ??
                  DateTime.now().millisecondsSinceEpoch,
              albumArt: albumArt,
              album: song['album']?.toString(),
            ));
          }
        }
        if (newSongs.isNotEmpty) {
          songs.value = newSongs;
        }
      }
    } catch (e) {
      debugPrint('Error fetching songs from device: $e');
    }
  }

  Future<Uint8List?> _loadAlbumArt(String path) async {
    try {
      final tag = await AudioTags.read(path);
      if (tag?.pictures.isNotEmpty == true) {
        return tag!.pictures.first.bytes;
      }
    } catch (e) {
      debugPrint('Error loading album art for $path: $e');
    }
    return null;
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
    final lowerQuery = query.toLowerCase();
    filteredSongs.value = query.isEmpty
        ? List<SongModel>.from(songs)
        : songs
            .where((song) =>
                song.title.toLowerCase().contains(lowerQuery) ||
                (song.artist?.toLowerCase().contains(lowerQuery) ?? false))
            .toList();
    sortSongs(SortType.nameAsc);
  }

  void sortSongs(SortType type) {
    final sorted = List<SongModel>.from(filteredSongs);
    _sortList(sorted, type);
    filteredSongs.value = sorted;
  }

  void _sortList(List<SongModel> list, SortType type) {
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

  // Added getAlbumArt method
  Widget getAlbumArt({double? width, double? height, SongModel? song}) {
    final targetSong = song ?? (songs.isNotEmpty ? songs.first : null);
    final size = width ?? 54;

    return targetSong?.albumArt != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              targetSong!.albumArt!,
              width: size,
              height: height ?? size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _defaultAlbumArt(size, height),
            ),
          )
        : _defaultAlbumArt(size, height);
  }

  Widget _defaultAlbumArt(double width, double? height) {
    return Container(
      width: width,
      height: height ?? width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade800,
      ),
      child: Icon(
        Icons.music_note,
        size: width * 0.5,
        color: Colors.white,
      ),
    );
  }
}
