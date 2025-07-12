import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/player_controller.dart';
import 'package:musify/controllers/favorite_controller.dart';
import 'package:musify/controllers/song_controller.dart';
import 'package:musify/services/album_art_service.dart';
import 'dart:typed_data';

class NowPlayingWidget extends StatefulWidget {
  final FavoriteController favoriteController;
  final SongController songController;
  final ScrollController? scrollController;

  const NowPlayingWidget({
    required this.favoriteController,
    required this.songController,
    this.scrollController,
    super.key,
  });

  State<NowPlayingWidget> createState() => _NowPlayingWidgetState();
}

class _NowPlayingWidgetState extends State<NowPlayingWidget> {
  // Enhanced caching system
  final Map<int, Uint8List?> _albumArtCache = {};
  final Map<int, Uint8List?> _blurredArtCache = {};
  final Set<int> _loadingImages = {};
  final Set<int> _preloadedImages = {};
  int? _currentSongId;
  int? _previousSongId;

  @override
  void initState() {
    super.initState();
    _initializeImageLoading();
  }

  void _initializeImageLoading() {
    final currentSong = Get.find<PlayerController>().currentSong.value;
    if (currentSong != null) {
      _currentSongId = currentSong.id;
      // Load current song immediately
      _loadImageForSong(currentSong, priority: true);
      // Preload next/previous songs
      _preloadAdjacentSongs();
    }

    // Listen to song changes
    Get.find<PlayerController>().currentSong.listen((song) {
      if (song != null && song.id != _currentSongId) {
        _handleSongChange(song);
      }
    });
  }

  void _handleSongChange(dynamic newSong) {
    if (newSong == null) return;
    
    _previousSongId = _currentSongId;
    _currentSongId = newSong.id;
    
    // If not already cached, load immediately
    if (!_albumArtCache.containsKey(newSong.id)) {
      _loadImageForSong(newSong, priority: true);
    }
    
    // Preload next songs in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAdjacentSongs();
    });
  }

  Future<void> _loadImageForSong(dynamic song, {bool priority = false}) async {
    if (song == null || _loadingImages.contains(song.id)) return;
    
    _loadingImages.add(song.id);
    
    try {
      // For priority loading (current song), load album art first, then blur
      if (priority) {
        // Load album art first (user sees it immediately)
        final albumArt = await AlbumArtService().getAlbumArt(song.path);
        if (mounted && _currentSongId == song.id) {
          setState(() {
            _albumArtCache[song.id] = albumArt;
          });
        }
        
        // Then load blurred art
        final blurredArt = await AlbumArtService().getBlurredAlbumArt(song.path, blur: 35);
        if (mounted && _currentSongId == song.id) {
          setState(() {
            _blurredArtCache[song.id] = blurredArt;
          });
        }
      } else {
        // For background preloading, load both concurrently
        final results = await Future.wait([
          AlbumArtService().getAlbumArt(song.path),
          AlbumArtService().getBlurredAlbumArt(song.path, blur: 35),
        ]);
        
        if (mounted) {
          setState(() {
            _albumArtCache[song.id] = results[0];
            _blurredArtCache[song.id] = results[1];
          });
        }
      }
      
      _preloadedImages.add(song.id);
    } catch (e) {
      // Handle error silently, placeholder will be shown
    } finally {
      _loadingImages.remove(song.id);
    }
  }

  void _preloadAdjacentSongs() {
    try {
      final playlist = widget.songController.songs;
      if (playlist.isEmpty) return;
      
      final currentIndex = playlist.indexWhere((song) => song.id == _currentSongId);
      if (currentIndex == -1) return;
      
      // Preload next 2 and previous 2 songs
      final indicesToPreload = <int>[];
      
      // Next songs
      for (int i = 1; i <= 2; i++) {
        final nextIndex = (currentIndex + i) % playlist.length;
        indicesToPreload.add(nextIndex);
      }
      
      // Previous songs
      for (int i = 1; i <= 2; i++) {
        final prevIndex = (currentIndex - i + playlist.length) % playlist.length;
        indicesToPreload.add(prevIndex);
      }
      
      // Load in background
      for (final index in indicesToPreload) {
        final song = playlist[index];
        if (!_preloadedImages.contains(song.id) && !_loadingImages.contains(song.id)) {
          _loadImageForSong(song, priority: false);
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final albumSize = (size.width * 0.65).clamp(280.0, 320.0);

    return Obx(() {
      final currentSong = Get.find<PlayerController>().currentSong.value;

      return Scaffold(
        body: Stack(
          children: [
            // Blurred album art background
            _buildBlurredBackground(currentSong),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    controller: widget.scrollController,
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            _buildHeader(context),
                            const SizedBox(height: 20),
                            _buildSongInfo(),
                            const SizedBox(height: 30),
                            _buildAlbumArt(albumSize),
                            const SizedBox(height: 30),
                            _buildProgress(context),
                            const SizedBox(height: 20),
                            _buildControls(),
                            const Spacer(),
                            SizedBox(height: MediaQuery.of(context).padding.bottom),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildBlurredBackground(dynamic currentSong) {
    final songId = currentSong?.id;
    final blurredArt = songId != null ? _blurredArtCache[songId] : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Always show the default background instantly
        _buildDefaultBackground(),
        // Fade in the blurred album art when ready
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: (blurredArt != null)
              ? Image.memory(
                  blurredArt,
                  key: ValueKey('blurred_bg_${songId ?? 'none'}'),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                )
              : const SizedBox.shrink(),
        ),
        // Dark overlay for readability
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.6),
                Colors.black.withOpacity(0.4),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade900,
            Colors.grey.shade800,
            Colors.black,
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        child: Column(
          children: [
            Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.8), size: 28),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  Get.find<PlayerController>().currentSong.value?.title ?? 'No Song',
                  key: ValueKey(Get.find<PlayerController>().currentSong.value?.id ?? 'none'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
          const SizedBox(height: 6),
          Obx(() => AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  Get.find<PlayerController>().currentSong.value?.artist ?? 'Unknown Artist',
                  key: ValueKey('artist_${Get.find<PlayerController>().currentSong.value?.id ?? 'none'}'),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(double size) {
    return Hero(
      tag: 'album_art_${Get.find<PlayerController>().currentSong.value?.id ?? 'default'}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Obx(() {
            final currentSong = Get.find<PlayerController>().currentSong.value;
            final albumArt = currentSong != null ? _albumArtCache[currentSong.id] : null;
            final isLoading = currentSong != null && _loadingImages.contains(currentSong.id);

            return Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: albumArt != null
                      ? Image.memory(
                          albumArt,
                          key: ValueKey<String>('art_${currentSong?.id ?? 'none'}'),
                          fit: BoxFit.cover,
                          width: size,
                          height: size,
                          errorBuilder: (context, error, stackTrace) => _buildArtPlaceholder(size),
                        )
                      : _buildArtPlaceholder(size),
                ),
                // Loading indicator
                if (isLoading)
                  Container(
                    width: size,
                    height: size,
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildArtPlaceholder(double size) {
    return Container(
      key: const ValueKey('placeholder'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade700,
            Colors.grey.shade800,
            Colors.grey.shade900,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: size * 0.35,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Obx(() {
        final position = Get.find<PlayerController>().position.value.inMilliseconds.toDouble();
        final duration = Get.find<PlayerController>().duration.value.inMilliseconds.toDouble();
        final effectiveDuration = duration > 0 ? duration : 1.0;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.3),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withOpacity(0.2),
              ),
              child: Slider(
                value: position.clamp(0.0, effectiveDuration),
                max: effectiveDuration,
                onChanged: effectiveDuration > 0
                    ? (v) {
                        Get.find<PlayerController>().seek(Duration(milliseconds: v.toInt()));
                        HapticFeedback.selectionClick();
                      }
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Get.find<PlayerController>().formatDuration(Get.find<PlayerController>().position.value),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  Get.find<PlayerController>().formatDuration(Get.find<PlayerController>().duration.value),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Secondary controls row - smaller and cleaner
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSecondaryButton(
                Icons.shuffle,
                () => Get.find<PlayerController>().toggleShuffle(),
                Get.find<PlayerController>().isShuffling,
              ),
              _buildFavoriteButton(),
              _buildSecondaryButton(
                Icons.repeat,
                () => Get.find<PlayerController>().toggleLoop(),
                Get.find<PlayerController>().isLooping,
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Main controls row - clean and minimal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(Icons.skip_previous, Get.find<PlayerController>().playPrevious),
              _buildPlayButton(),
              _buildControlButton(Icons.skip_next, Get.find<PlayerController>().playNext),
            ],
          ),
        ],
      ),
    );
  }

  // Clean secondary buttons - no backgrounds, just icons
  Widget _buildSecondaryButton(IconData icon, VoidCallback onTap, RxBool state) {
    return Obx(() => GestureDetector(
          onTap: () {
            onTap();
            HapticFeedback.lightImpact();
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              color: state.value ? Colors.white : Colors.white.withOpacity(0.6),
              size: 20,
            ),
          ),
        ));
  }

  // Clean favorite button - no background
  Widget _buildFavoriteButton() {
    return Obx(() {
      final song = Get.find<PlayerController>().currentSong.value;
      final isFav = song != null && widget.favoriteController.isFavorite(song.path);

      return GestureDetector(
        onTap: song != null
            ? () {
                widget.favoriteController.toggleFavorite(song.path);
                HapticFeedback.lightImpact();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.redAccent : Colors.white.withOpacity(0.6),
            size: 20,
          ),
        ),
      );
    });
  }

  // Clean control buttons - no backgrounds
  Widget _buildControlButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        HapticFeedback.mediumImpact();
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Icon(
          icon, 
          color: Colors.white.withOpacity(0.9), 
          size: 24,
        ),
      ),
    );
  }

  // Clean play button - only white background, no extra shadows
  Widget _buildPlayButton() {
    return Obx(() => GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            Get.find<PlayerController>().isPlaying.value
                ? Get.find<PlayerController>().pause()
                : Get.find<PlayerController>().resume();
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              Get.find<PlayerController>().isPlaying.value ? Icons.pause : Icons.play_arrow,
              color: Colors.black,
              size: 28,
            ),
          ),
        ));
  }

  @override
  void dispose() {
    _albumArtCache.clear();
    _blurredArtCache.clear();
    _loadingImages.clear();
    _preloadedImages.clear();
    super.dispose();
  }
}