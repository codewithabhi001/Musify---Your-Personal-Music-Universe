import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musify/controllers/song_controller.dart';
import 'package:musify/controllers/player_controller.dart';
import 'package:musify/controllers/favorite_controller.dart';
import 'package:musify/model/song_model.dart';

class SearchPage extends StatelessWidget {
  final SongController songController = Get.find<SongController>();
  final PlayerController playerController = Get.find<PlayerController>();
  final FavoriteController favoriteController = Get.find<FavoriteController>();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                songController.searchSongs('');
              },
            ),
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
                ? const Center(child: Text('No songs found'))
                : ListView.builder(
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
                            fontWeight:
                                isPlaying ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          song.artist ?? 'Unknown',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
                        onTap: () => playerController.play(song),
                      );
                    },
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
}
