import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/song_model.dart';
import 'song_controller.dart';

class FavoriteController extends GetxController {
  final favorites = <String>[].obs;
  final filteredFavorites = <SongModel>[].obs;

  List<SongModel> get favoritesList => Get.find<SongController>()
      .songs
      .where((s) => favorites.contains(s.path))
      .toList();

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      favorites.value = prefs.getStringList('favorites') ?? [];
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  void toggleFavorite(String path) {
    if (favorites.contains(path)) {
      favorites.remove(path);
    } else {
      favorites.add(path);
    }
    filteredFavorites.value = favoritesList;
    _saveState();
  }

  bool isFavorite(String path) => favorites.contains(path);

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorites', favorites.toList());
    } catch (e) {
      debugPrint('Error saving state: $e');
    }
  }

  void searchFavorites(String query) {
    final lowerQuery = query.toLowerCase();
    filteredFavorites.value = query.isEmpty
        ? List<SongModel>.from(favoritesList)
        : favoritesList
            .where((song) =>
                song.title.toLowerCase().contains(lowerQuery) ||
                (song.artist?.toLowerCase().contains(lowerQuery) ?? false))
            .toList();
    sortFavorites(SortType.nameAsc);
  }

  void sortFavorites(SortType type) {
    final sorted = List<SongModel>.from(filteredFavorites);
    _sortList(sorted, type);
    filteredFavorites.value = sorted;
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
}
