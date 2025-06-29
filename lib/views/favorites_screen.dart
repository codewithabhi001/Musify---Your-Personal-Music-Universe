import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:musify/controllers/player_controller.dart';
import 'package:musify/controllers/song_controller.dart';
import 'package:musify/controllers/favorite_controller.dart';

class FavoritesWidget extends StatelessWidget {
  final FavoriteController favoriteController = Get.find<FavoriteController>();
  final PlayerController playerController = Get.find<PlayerController>();
  final SongController songController = Get.find<SongController>();

  FavoritesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => songController.isLoading.value // Changed from favoriteController
            ? const Center(child: CircularProgressIndicator())
            : favoriteController.filteredFavorites.isEmpty
                ? Center(
                    child: Text(
                      'No Favorite Songs',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                : ListView.builder(
                    cacheExtent: 1000,
                    itemCount: favoriteController.filteredFavorites.length,
                    itemBuilder: (context, index) {
                      final song = favoriteController.filteredFavorites[index];
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
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () =>
                              favoriteController.toggleFavorite(song.path),
                        ),
                        onTap: () => playerController.play(),
                      );
                    },
                  ),
      ),
    );
  }
}

class FavoriteSearchDelegate extends SearchDelegate {
  final FavoriteController favoriteController;
  final PlayerController playerController;
  final SongController songController;

  FavoriteSearchDelegate(
    this.favoriteController,
    this.playerController,
    this.songController,
  );

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    favoriteController.searchFavorites(query);
    return Obx(
      () => songController.isLoading.value // Changed from favoriteController
          ? const Center(child: CircularProgressIndicator())
          : favoriteController.filteredFavorites.isEmpty
              ? const Center(child: Text('No favorite songs found'))
              : ListView.builder(
                  cacheExtent: 1000,
                  itemCount: favoriteController.filteredFavorites.length,
                  itemBuilder: (context, index) {
                    final song = favoriteController.filteredFavorites[index];
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite, color: Colors.red),
                        onPressed: () =>
                            favoriteController.toggleFavorite(song.path),
                      ),
                      onTap: () => playerController.play(),
                    );
                  },
                ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const SizedBox.shrink();
  }
}
