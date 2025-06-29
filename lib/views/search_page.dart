import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musify/controllers/song_controller.dart';
import 'package:musify/controllers/player_controller.dart';
import 'package:musify/controllers/favorite_controller.dart';
import 'package:musify/model/song_model.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SongController songController = Get.find<SongController>();
  final PlayerController playerController = Get.find<PlayerController>();
  final FavoriteController favoriteController = Get.find<FavoriteController>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _hasSearchText = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _hasSearchText = _searchController.text.isNotEmpty;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    songController.searchSongs('');
    setState(() {
      _hasSearchText = false;
    });
  }

  void _resetSearchOnBack() {
    // Reset search when going back
    songController.searchSongs('');
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) {
        if (didPop) {
          _resetSearchOnBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _resetSearchOnBack();
              Navigator.of(context).pop();
            },
          ),
          title: TextField(
            controller: _searchController,
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                songController.searchSongs(value);
              });
            },
            decoration: InputDecoration(
              hintText: 'Search songs...',
              border: InputBorder.none,
              suffixIcon: _hasSearchText
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
            ),
            style: Theme.of(context).textTheme.bodyLarge,
            autofocus: true,
          ),
          actions: [
            PopupMenuButton<SortType>(
              icon: const Icon(Icons.sort),
              onSelected: (value) => songController.sortSongs(value),
              itemBuilder: (context) => SortType.values
                  .map((type) => PopupMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(
                              _getSortIcon(type),
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(width: 8),
                            Text(GetUtils.capitalizeFirst!(type.name) ?? ''),
                          ],
                        ),
                      ))
                  .toList(),
              tooltip: 'Sort by',
            ),
          ],
        ),
        body: Obx(
          () => songController.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : songController.filteredSongs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _hasSearchText
                                ? 'No songs found'
                                : 'Start typing to search songs',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemExtent: context.isPhone ? 70 : 80,
                      cacheExtent: 1000,
                      itemCount: songController.filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = songController.filteredSongs[index];
                        final isPlaying =
                            playerController.currentSong.value?.id == song.id &&
                                playerController.isPlaying.value;
                        return ListTile(
                          leading: songController.getAlbumArt(
                            song: song,
                            width: 54,
                            height: 54,
                          ),
                          title: Text(
                            song.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isPlaying
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isPlaying
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            song.artist ?? 'Unknown',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              favoriteController.isFavorite(song.path)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: favoriteController.isFavorite(song.path)
                                  ? Colors.red
                                  : null,
                            ),
                            onPressed: () =>
                                favoriteController.toggleFavorite(song.path),
                          ),
                          onTap: () => playerController.play(),
                        );
                      },
                    ),
        ),
      ),
    );
  }

  IconData _getSortIcon(SortType type) {
    switch (type) {
      case SortType.nameAsc:
        return Icons.sort_by_alpha;
      case SortType.nameDesc:
        return Icons.sort_by_alpha;
      case SortType.artist:
        return Icons.person;
      case SortType.recent:
        return Icons.access_time;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}
