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

  AllSongsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
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
        return _OptimizedSongListView(
          songs: songController.filteredSongs,
          songController: songController,
          playerController: playerController,
          favoriteController: favoriteController,
        );
      }),
    );
  }
}

class _OptimizedSongListView extends StatefulWidget {
  final List<SongModel> songs;
  final SongController songController;
  final PlayerController playerController;
  final FavoriteController favoriteController;

  const _OptimizedSongListView({
    required this.songs,
    required this.songController,
    required this.playerController,
    required this.favoriteController,
  });

  @override
  _OptimizedSongListViewState createState() => _OptimizedSongListViewState();
}

class _OptimizedSongListViewState extends State<_OptimizedSongListView> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, int> _letterIndices = {};
  final Map<String, bool> _hasSongsCache = {};

  @override
  void initState() {
    super.initState();
    _updateCaches();
  }

  @override
  void didUpdateWidget(_OptimizedSongListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.songs != widget.songs) {
      _updateCaches();
    }
  }

  void _updateCaches() {
    _letterIndices.clear();
    _hasSongsCache.clear();

    for (var i = 0; i < widget.songs.length; i++) {
      final title = widget.songs[i].title;
      if (title.isNotEmpty) {
        final letter = title[0].toUpperCase();
        _letterIndices.putIfAbsent(letter, () => i);
        _hasSongsCache[letter] = true;
      }
    }
  }

  void _jumpToLetter(String letter) {
    if (!_scrollController.hasClients || widget.songs.isEmpty) return;
    final index = _letterIndices[letter];
    if (index != null) {
      _scrollController.animateTo(
        index * 72.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Optimized ListView with better performance
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(right: 30, bottom: 10),
          itemExtent: 72.0, // Fixed height for better performance
          physics: const AlwaysScrollableScrollPhysics(), // Smooth scrolling
          itemCount: widget.songs.length,
          itemBuilder: (context, index) {
            final song = widget.songs[index];
            return _OptimizedSongTile(
              key: ValueKey('${song.id}_${song.path}'), // Stable key
              song: song,
              playerController: widget.playerController,
              favoriteController: widget.favoriteController,
              songController: widget.songController,
            );
          },
        ),
        // Simplified alphabet scrollbar
        _SimpleAlphabetScrollBar(
          hasSongsCache: _hasSongsCache,
          onLetterTap: _jumpToLetter,
        ),
      ],
    );
  }
}

class _OptimizedSongTile extends StatelessWidget {
  final SongModel song;
  final PlayerController playerController;
  final FavoriteController favoriteController;
  final SongController songController;

  const _OptimizedSongTile({
    super.key,
    required this.song,
    required this.playerController,
    required this.favoriteController,
    required this.songController,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentSongId = playerController.currentSong.value?.id;
      final isPlaying = playerController.isPlaying.value;
      final isCurrentPlaying = currentSongId == song.id && isPlaying;
      final isFavorite = favoriteController.isFavorite(song.path);

      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        // Optimized album art with caching
        leading: _OptimizedAlbumArt(
          song: song,
          songController: songController,
          size: 48,
        ),
        title: Text(
          song.title,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontWeight: isCurrentPlaying ? FontWeight.bold : FontWeight.w500,
            color:
                isCurrentPlaying ? Theme.of(context).colorScheme.primary : null,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          song.artist ?? 'Unknown Artist',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            fontSize: 12,
            color: isCurrentPlaying
                ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentPlaying)
              Icon(
                Icons.graphic_eq,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => favoriteController.toggleFavorite(song.path),
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : Colors.grey,
                size: 20,
              ),
            ),
          ],
        ),
        onTap: () => playerController.playSong(song),
      );
    });
  }
}

class _OptimizedAlbumArt extends StatefulWidget {
  final SongModel song;
  final SongController songController;
  final double size;

  const _OptimizedAlbumArt({
    required this.song,
    required this.songController,
    required this.size,
  });

  @override
  _OptimizedAlbumArtState createState() => _OptimizedAlbumArtState();
}

class _OptimizedAlbumArtState extends State<_OptimizedAlbumArt> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: widget.songController.getAlbumArt(
          song: widget.song,
          width: widget.size,
          height: widget.size,
        ),
      ),
    );
  }
}

class _SimpleAlphabetScrollBar extends StatelessWidget {
  final Map<String, bool> hasSongsCache;
  final void Function(String) onLetterTap;

  const _SimpleAlphabetScrollBar({
    required this.hasSongsCache,
    required this.onLetterTap,
  });

  @override
  Widget build(BuildContext context) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    return Positioned(
      right: 4,
      top: 50,
      bottom: 50,
      width: 20,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: letters.split('').map((letter) {
            final hasSongs = hasSongsCache[letter] ?? false;
            return GestureDetector(
              onTap: hasSongs ? () => onLetterTap(letter) : null,
              child: Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: hasSongs ? FontWeight.bold : FontWeight.normal,
                    color: hasSongs
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
