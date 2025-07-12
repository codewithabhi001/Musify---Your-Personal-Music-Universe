import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:musify/controllers/song_controller.dart';
import 'package:musify/controllers/player_controller.dart';
import 'package:musify/model/song_model.dart';
import 'package:musify/services/album_art_service.dart';
import 'dart:typed_data';

class SongListPage extends GetView<SongController> {
  final PlayerController playerController = Get.find<PlayerController>();
  final String title;
  final List<SongModel> songs;
  final ScrollController _scrollController = ScrollController();

  SongListPage({required this.title, required this.songs, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        controller: _scrollController,
        cacheExtent: 1000, // Increase cache extent for better performance
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
      if (controller.isLoading.value) {
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (songs.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
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
        sliver: SliverList.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) => _SongTile(
            key: ValueKey(songs[index].id), // Add key for better performance
            song: songs[index],
            songController: controller,
            playerController: playerController,
            index: index,
          ),
        ),
      );
    });
  }
}

class _SongTile extends StatefulWidget {
  final SongModel song;
  final SongController songController;
  final PlayerController playerController;
  final int index;

  const _SongTile({
    required Key key,
    required this.song,
    required this.songController,
    required this.playerController,
    required this.index,
  }) : super(key: key);

  @override
  State<_SongTile> createState() => _SongTileState();
}

class _SongTileState extends State<_SongTile>
    with AutomaticKeepAliveClientMixin {
  Uint8List? _cachedAlbumArt;
  bool _isLoadingAlbumArt = false;

  @override
  bool get wantKeepAlive => true; // Keep tiles alive for better scrolling

  @override
  void initState() {
    super.initState();
    _loadAlbumArt();
  }

  Future<void> _loadAlbumArt() async {
    if (_cachedAlbumArt != null || _isLoadingAlbumArt) return;

    setState(() {
      _isLoadingAlbumArt = true;
    });

    try {
      final albumArt = await AlbumArtService().getAlbumArt(widget.song.path);
      if (mounted) {
        setState(() {
          _cachedAlbumArt = albumArt;
          _isLoadingAlbumArt = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAlbumArt = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Obx(() {
      final isPlaying =
          widget.playerController.currentSong.value?.id == widget.song.id &&
              widget.playerController.isPlaying.value;

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
          onTap: () => widget.playerController.play(widget.song),
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
    if (_cachedAlbumArt != null) {
      return Image.memory(
        _cachedAlbumArt!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    if (_isLoadingAlbumArt) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: 28),
    );
  }

  Widget _buildSongInfo(BuildContext context, bool isPlaying) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.song.title,
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
                widget.song.artist ?? 'Unknown Artist',
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
