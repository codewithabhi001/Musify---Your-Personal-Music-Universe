import 'dart:io';

import '../models/song_model.dart';
import '../services/method_channel_service.dart';

class SongRepository {
  
  // More permissive music file extensions
  static const List<String> _musicExtensions = [
    'mp3', 'm4a', 'flac', 'wma', 'aiff', 'ogg', 'wav', 'aac', 'opus', 'm4r'
  ];

  // Only block very specific system recording directories
  static const List<String> _blacklistedDirs = [
    'Android/data/com.android.soundrecorder',
    'Android/data/com.google.android.apps.recorder',
    'Android/data/com.samsung.android.voice.recorder',
    'Android/data/com.sec.android.app.voicenote',
    'Recordings',
    'Voice Recorder',
    'Call Recorder'
  ];

  Future<List<Song>> getAllSongs() async {
    try {
      // Try method channel first (faster)
      final songs = await MethodChannelService.getSongsFromDevice();
      if (songs.isNotEmpty) {
        return songs;
      }
    } catch (e) {
      print('Method channel failed, falling back to file scanning: $e');
    }

    // Fallback to file scanning
    return await _scanMusicFiles();
  }

  Future<List<Song>> _scanMusicFiles() async {
    final List<Song> songs = [];
    
    try {
      // Remove permission request logic
      // Scan common music directories
      final directories = [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Music',
        '/storage/emulated/0/DCIM',
        '/storage/emulated/0/Pictures',
        '/storage/emulated/0/Android/data',
        '/storage/emulated/0/Android/media',
      ];

      for (final dirPath in directories) {
        try {
          final dir = Directory(dirPath);
          if (await dir.exists()) {
            await _scanDirectory(dir, songs);
          }
        } catch (e) {
          print('Error scanning directory $dirPath: $e');
        }
      }

      // Also scan external storage if available
      try {
        final externalDir = Directory('/storage');
        if (await externalDir.exists()) {
          await _scanDirectory(externalDir, songs);
        }
      } catch (e) {
        print('Error scanning external storage: $e');
      }

    } catch (e) {
      print('Error scanning music files: $e');
      throw Exception('Failed to scan music files: $e');
    }

    return songs;
  }

  Future<void> _scanDirectory(Directory directory, List<Song> songs) async {
    try {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          await _processFile(entity, songs);
        }
      }
    } catch (e) {
      // Skip directories that can't be accessed
      print('Cannot access directory ${directory.path}: $e');
    }
  }

  Future<void> _processFile(File file, List<Song> songs) async {
    try {
      final path = file.path.toLowerCase();
      
      // Check if file is blacklisted
      if (_isBlacklisted(path)) {
        return;
      }

      // Check if it's a music file
      if (!_isMusicFile(path)) {
        return;
      }

      // Get file info
      final stat = await file.stat();
      if (stat.size < 100000) { // Skip files smaller than 100KB
        return;
      }

      // Create song object
      final song = Song(
        id: file.path.hashCode.toString(),
        title: _extractTitle(file.path),
        artist: _extractArtist(file.path),
        album: _extractAlbum(file.path),
        path: file.path,
        duration: Duration(milliseconds: await _getDuration(file)),
        trackNumber: null,
        year: null,
        genre: null,
        isFavorite: false,
      );

      // Avoid duplicates
      if (!songs.any((s) => s.path == song.path)) {
        songs.add(song);
      }

    } catch (e) {
      // Skip files that can't be processed
      print('Error processing file ${file.path}: $e');
    }
  }

  bool _isBlacklisted(String path) {
    for (final dir in _blacklistedDirs) {
      if (path.contains(dir.toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  bool _isMusicFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return _musicExtensions.contains(extension);
  }

  String _extractTitle(String path) {
    final fileName = path.split('/').last;
    final nameWithoutExt = fileName.split('.').first;
    
    // Try to extract title from filename
    if (nameWithoutExt.contains('-')) {
      final parts = nameWithoutExt.split('-');
      if (parts.length >= 2) {
        return parts[1].trim();
      }
    }
    
    return nameWithoutExt.replaceAll('_', ' ').trim();
  }

  String _extractArtist(String path) {
    final fileName = path.split('/').last;
    final nameWithoutExt = fileName.split('.').first;
    
    // Try to extract artist from filename
    if (nameWithoutExt.contains('-')) {
      final parts = nameWithoutExt.split('-');
      if (parts.length >= 2) {
        return parts[0].trim();
      }
    }
    
    return 'Unknown Artist';
  }

  String _extractAlbum(String path) {
    // Try to extract album from directory name
    final dirs = path.split('/');
    if (dirs.length >= 2) {
      final parentDir = dirs[dirs.length - 2];
      if (parentDir.isNotEmpty && parentDir != 'Download' && parentDir != 'Music') {
        return parentDir.replaceAll('_', ' ').trim();
      }
    }
    
    return 'Unknown Album';
  }

  Future<int> _getDuration(File file) async {
    try {
      // For now, return a default duration
      // In a real implementation, you'd use a library like just_audio to get actual duration
      return 180000; // 3 minutes default
    } catch (e) {
      return 180000;
    }
  }

  Future<List<Song>> searchSongs(String query) async {
    final allSongs = await getAllSongs();
    if (query.isEmpty) return allSongs;

    final lowercaseQuery = query.toLowerCase();
    return allSongs.where((song) {
      return song.title.toLowerCase().contains(lowercaseQuery) ||
             song.artist.toLowerCase().contains(lowercaseQuery) ||
             song.album.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  Future<List<Song>> sortSongs(List<Song> songs, SortType sortType) async {
    switch (sortType) {
      case SortType.nameAsc:
        songs.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortType.nameDesc:
        songs.sort((a, b) => b.title.compareTo(a.title));
        break;
      case SortType.artist:
        songs.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case SortType.album:
        songs.sort((a, b) => a.album.compareTo(b.album));
        break;
      case SortType.duration:
        songs.sort((a, b) => a.duration.compareTo(b.duration));
        break;
      case SortType.recent:
        // For now, keep original order
        break;
      case SortType.favorite:
        songs.sort((a, b) => b.isFavorite.toString().compareTo(a.isFavorite.toString()));
        break;
    }
    return songs;
  }

  Future<void> toggleFavorite(String songId) async {
    // In a real app, you'd save this to local storage or database
    // For now, we'll just print the action
    print('Toggling favorite for song: $songId');
  }

  Future<List<Song>> getFavoriteSongs() async {
    final allSongs = await getAllSongs();
    return allSongs.where((song) => song.isFavorite).toList();
  }

  Future<List<Artist>> getArtists() async {
    final songs = await getAllSongs();
    final artistMap = <String, List<Song>>{};
    
    for (final song in songs) {
      artistMap.putIfAbsent(song.artist, () => []).add(song);
    }
    
    return artistMap.entries.map((entry) {
      return Artist(
        name: entry.key,
        songs: entry.value,
      );
    }).toList();
  }

  Future<List<Album>> getAlbums() async {
    final songs = await getAllSongs();
    final albumMap = <String, List<Song>>{};
    
    for (final song in songs) {
      albumMap.putIfAbsent(song.album, () => []).add(song);
    }
    
    return albumMap.entries.map((entry) {
      return Album(
        name: entry.key,
        artist: entry.value.first.artist,
        songs: entry.value,
      );
    }).toList();
  }
} 