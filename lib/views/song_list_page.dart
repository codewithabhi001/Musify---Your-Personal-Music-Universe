import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:musify/controllers/song_controller.dart';
import 'package:musify/controllers/player_controller.dart';
import 'package:musify/model/song_model.dart';

class SongListPage extends StatelessWidget {
  final SongController songController = Get.find<SongController>();
  final PlayerController playerController = Get.find<PlayerController>();
  final String title;
  final List<SongModel> songs;
  final ScrollController _scrollController = ScrollController();

  SongListPage({required this.title, required this.songs, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(context),
          _buildSongsList(context),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
      ),
    );
  }

  Widget _buildSongsList(BuildContext context) {
    return Obx(() {
      if (songController.isLoading.value) {
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (songs.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.music_note,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No songs found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _SongTile(
              song: songs[index],
              songController: songController,
              playerController: playerController,
              index: index,
            ),
            childCount: songs.length,
          ),
        ),
      );
    });
  }
}

class _SongTile extends StatelessWidget {
  final SongModel song;
  final SongController songController;
  final PlayerController playerController;
  final int index;

  const _SongTile({
    required this.song,
    required this.songController,
    required this.playerController,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isPlaying = playerController.currentSong.value?.id == song.id &&
          playerController.isPlaying.value;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isPlaying
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4)
              : Theme.of(context).colorScheme.surface.withOpacity(0.1),
          border: isPlaying
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                  width: 2,
                )
              : null,
          boxShadow: isPlaying
              ? [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.01),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => playerController.playSong(song),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildAlbumArt(context, isPlaying),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSongInfo(context, isPlaying),
                ),
                _buildPlayingIndicator(context, isPlaying),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAlbumArt(BuildContext context, bool isPlaying) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                songController.getAlbumArt(song: song, width: 56, height: 56),
          ),
          if (isPlaying)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.3),
              ),
              child: Center(
                child: Icon(
                  playerController.isPlaying.value
                      ? Icons.pause
                      : Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context, bool isPlaying) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song.title,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isPlaying
                ? Theme.of(context).colorScheme.tertiaryFixed
                : Theme.of(context).colorScheme.onSurface,
            fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                song.artist ?? 'Unknown Artist',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isPlaying
                      ? null
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlayingIndicator(BuildContext context, bool isPlaying) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isPlaying ? 32 : 0,
      child: isPlaying
          ? Icon(
              Icons.graphic_eq,
              size: 20,
            )
          : null,
    );
  }
}
