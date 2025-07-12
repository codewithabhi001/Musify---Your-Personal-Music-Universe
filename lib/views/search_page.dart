import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/song_controller.dart';
import 'package:musify/controllers/player_controller.dart';
import 'package:musify/controllers/favorite_controller.dart';
import 'package:musify/model/song_model.dart';
import 'package:musify/services/album_art_service.dart';
import 'dart:typed_data';

class SearchPage extends StatefulWidget {
  SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SongController controller = Get.find<SongController>();
  final PlayerController playerController = Get.find<PlayerController>();
  final FavoriteController favoriteController = Get.find<FavoriteController>();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;
  final RxString searchquery = ''.obs;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      searchquery.value = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        controller.resetSearch();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _searchController,
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                controller.searchSongs(value);
              });
            },
            decoration: InputDecoration(
              hintText: 'Search songs...',
              border: InputBorder.none,
              suffixIcon: Obx(() => searchquery.value.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  controller.searchSongs('');
                },
              )
                  : const SizedBox.shrink()),
            ),
            style: Theme.of(context).textTheme.bodyLarge,
            autofocus: true,
          ),
          actions: [
            PopupMenuButton<SortType>(
              icon: const Icon(Icons.sort),
              onSelected: (value) => controller.sortSongs(value),
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
                    Text(GetUtils.capitalizeFirst(type.name) ?? ''),
                  ],
                ),
              ))
                  .toList(),
              tooltip: 'Sort by',
            ),
          ],
        ),
        body: Obx(
              () => controller.isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : controller.filteredSongs.isEmpty
              ? const Center(child: Text('No songs found'))
              : ListView.builder(
            cacheExtent: 1000,
            itemCount: controller.filteredSongs.length,
            itemBuilder: (context, index) {
              final song = controller.filteredSongs[index];
              return _SearchSongTile(
                key: ValueKey(song.id),
                song: song,
                playerController: playerController,
                favoriteController: favoriteController,
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
}

class _SearchSongTile extends StatefulWidget {
  final SongModel song;
  final PlayerController playerController;
  final FavoriteController favoriteController;

  const _SearchSongTile({
    required Key key,
    required this.song,
    required this.playerController,
    required this.favoriteController,
  }) : super(key: key);

  @override
  State<_SearchSongTile> createState() => _SearchSongTileState();
}

class _SearchSongTileState extends State<_SearchSongTile> with AutomaticKeepAliveClientMixin {
  Uint8List? _cachedAlbumArt;
  bool _isLoadingAlbumArt = false;

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    
    return Obx(() {
      final isPlaying = widget.playerController.currentSong.value?.id == widget.song.id &&
          widget.playerController.isPlaying.value;

      return ListTile(
        leading: _buildAlbumArt(),
        title: Text(
          widget.song.title,
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
          widget.song.artist ?? 'Unknown',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color:
            Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            widget.favoriteController.isFavorite(widget.song.path)
                ? Icons.favorite
                : Icons.favorite_border,
            color: widget.favoriteController.isFavorite(widget.song.path)
                ? Colors.red
                : null,
          ),
          onPressed: () =>
              widget.favoriteController.toggleFavorite(widget.song.path),
        ),
        onTap: () => widget.playerController.play(widget.song),
      );
    });
  }

  Widget _buildAlbumArt() {
    if (_cachedAlbumArt != null) {
      return Image.memory(
        _cachedAlbumArt!,
        width: 54,
        height: 54,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    if (_isLoadingAlbumArt) {
      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
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
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note, color: Colors.white, size: 28),
    );
  }
}
