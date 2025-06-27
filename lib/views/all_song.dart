import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musify/controllers/player_controller.dart';
import 'package:musify/controllers/song_controller.dart';
import 'package:musify/controllers/favorite_controller.dart';
import 'package:musify/model/song_model.dart';

class AllSongsPage extends StatelessWidget {
  final SongController songController = Get.find<SongController>();
  final PlayerController playerController = Get.find<PlayerController>();
  final FavoriteController favoriteController = Get.find<FavoriteController>();
  final ScrollController _scrollController = ScrollController();

  AllSongsPage({super.key}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (songController.filteredSongs.isNotEmpty) {
        songController.sortSongs(SortType.nameAsc);
        _scrollToLetter('A');
      }
    });
  }

  void _scrollToLetter(String letter) {
    final index = songController.filteredSongs.indexWhere(
        (s) => s.title.isNotEmpty && s.title[0].toUpperCase() == letter);
    if (index != -1) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          index * 72.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Obx(() {
              if (songController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (songController.filteredSongs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.music_note, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No songs found', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                );
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(right: 30, bottom: 10),
                    itemCount: songController.filteredSongs.length,
                    itemBuilder: (context, index) => _SongTile(
                      key: ValueKey(songController.filteredSongs[index].id),
                      song: songController.filteredSongs[index],
                      playerController: playerController,
                      favoriteController: favoriteController,
                      songController: songController,
                    ),
                  ),
                  _AlphabetScrollBar(
                    scrollController: _scrollController,
                    songs: songController.filteredSongs,
                    songController: songController,
                  ),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final SongModel song;
  final PlayerController playerController;
  final FavoriteController favoriteController;
  final SongController songController;

  const _SongTile({
    super.key,
    required this.song,
    required this.playerController,
    required this.favoriteController,
    required this.songController,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      minVerticalPadding: 0,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 50,
          height: 50,
          child: songController.getAlbumArt(song: song, width: 50, height: 50),
        ),
      ),
      title: Obx(() {
        final isCurrentPlaying =
            playerController.currentSong.value?.id == song.id &&
                playerController.isPlaying.value;
        return Text(
          song.title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isCurrentPlaying ? FontWeight.bold : FontWeight.w500,
            color: isCurrentPlaying
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
          ),
        );
      }),
      subtitle: Obx(() {
        final isCurrentPlaying =
            playerController.currentSong.value?.id == song.id &&
                playerController.isPlaying.value;
        return Row(
          children: [
            Expanded(
              child: Text(
                song.artist ?? 'Unknown Artist',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrentPlaying
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            isCurrentPlaying
                ? Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.graphic_eq,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        );
      }),
      trailing: Obx(() {
        final isFav = favoriteController.isFavorite(song.path);
        return GestureDetector(
          onTap: () => favoriteController.toggleFavorite(song.path),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFav ? Colors.red.withOpacity(0.1) : Colors.transparent,
            ),
            child: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : Colors.grey,
              size: 22,
            ),
          ),
        );
      }),
      onTap: () => playerController.play(song),
    );
  }
}

class _AlphabetScrollBar extends StatelessWidget {
  final ScrollController scrollController;
  final List<SongModel> songs;
  final SongController songController;

  _AlphabetScrollBar({
    required this.scrollController,
    required this.songs,
    required this.songController,
  });

  final List<String> letters =
      List.generate(26, (i) => String.fromCharCode(65 + i));

  void _jumpTo(String letter) {
    final index = songs.indexWhere(
        (s) => s.title.isNotEmpty && s.title[0].toUpperCase() == letter);
    if (index != -1) {
      scrollController.animateTo(
        index * 72.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 4,
      top: 20,
      bottom: 20,
      width: 24,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: letters.map((letter) {
              final hasSongs = songs.any((s) =>
                  s.title.isNotEmpty && s.title[0].toUpperCase() == letter);
              return GestureDetector(
                onTap: () => _jumpTo(letter),
                child: Container(
                  height: 18,
                  width: 18,
                  alignment: Alignment.center,
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: hasSongs ? FontWeight.bold : FontWeight.w400,
                      color: hasSongs
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.3),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
