import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:musify/controllers/player_controller.dart';
import 'package:musify/controllers/favorite_controller.dart';
import 'package:musify/controllers/song_controller.dart';

class NowPlayingWidget extends StatefulWidget {
  final PlayerController playerController;
  final FavoriteController favoriteController;
  final SongController songController;
  final ScrollController? scrollController;

  const NowPlayingWidget({
    required this.playerController,
    required this.favoriteController,
    required this.songController,
    this.scrollController,
    super.key,
  });

  @override
  _NowPlayingWidgetState createState() => _NowPlayingWidgetState();
}

class _NowPlayingWidgetState extends State<NowPlayingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _currentSongPath;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Map<String, Color> _getDefaultColorMap() {
    return {
      'dominant': const Color(0xFF2A2A2A),
      'accent': const Color(0xFF3A3A3A),
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final albumSize = (size.width * 0.65).clamp(280.0, 320.0);

    return Obx(() {
      final currentSong = widget.playerController.currentSong.value;
      final songPath = currentSong?.path;

      if (songPath != _currentSongPath) {
        _animationController.reset();
        _animationController.forward();
        _currentSongPath = songPath;
      }

      final colors = songPath != null
          ? widget.songController.getCachedColors(songPath)
          : _getDefaultColorMap();
      final dominantColor = colors['dominant']!;
      final accentColor = colors['accent']!;

      return Scaffold(
        body: Container(
          height: size.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                dominantColor.withOpacity(0.1),
                dominantColor.withOpacity(0.3),
                dominantColor.withOpacity(0.2),
                dominantColor.withOpacity(0.1),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: widget.scrollController,
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 20),
                          _buildSongInfo(),
                          const SizedBox(height: 30),
                          _buildAlbumArt(albumSize, accentColor),
                          const SizedBox(height: 30),
                          _buildProgress(context),
                          const SizedBox(height: 20),
                          _buildControls(dominantColor),
                          const Spacer(),
                          SizedBox(
                              height: MediaQuery.of(context).padding.bottom),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
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
            Icon(Icons.keyboard_arrow_down,
                color: Colors.white.withOpacity(0.8), size: 28),
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
          Obx(() => Text(
                widget.playerController.currentSong.value?.title ?? 'No Song',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
          const SizedBox(height: 6),
          Obx(() => Text(
                widget.playerController.currentSong.value?.artist ??
                    'Unknown Artist',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(double size, Color accentColor) {
    return Hero(
      tag:
          'album_art_${widget.playerController.currentSong.value?.id ?? 'default'}',
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Obx(() {
              final song = widget.playerController.currentSong.value;
              if (song == null) {
                return Container(
                  color: accentColor,
                  child: Icon(Icons.music_note,
                      size: size * 0.3, color: Colors.white54),
                );
              }
              return FutureBuilder<Uint8List?>(
                future: widget.songController.loadAlbumArt(song.path),
                builder: (context, snapshot) {
                  Widget imageWidget;
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData &&
                      snapshot.data != null) {
                    imageWidget = Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      width: size,
                      height: size,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Album art render error: $error');
                        return Container(
                          color: accentColor,
                          child: Icon(Icons.music_note,
                              size: size * 0.3, color: Colors.white54),
                        );
                      },
                    );
                  } else {
                    imageWidget = Container(
                      color: accentColor,
                      child: Icon(Icons.music_note,
                          size: size * 0.3, color: Colors.white54),
                    );
                  }
                  return imageWidget;
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Obx(() {
        final position =
            widget.playerController.position.value.inMilliseconds.toDouble();
        final duration =
            widget.playerController.duration.value.inMilliseconds.toDouble();
        final effectiveDuration = duration > 0 ? duration : 1.0;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withOpacity(0.2),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withOpacity(0.1),
              ),
              child: Slider(
                value: position.clamp(0.0, effectiveDuration),
                max: effectiveDuration,
                onChanged: effectiveDuration > 0
                    ? (v) => widget.playerController
                        .seek(Duration(milliseconds: v.toInt()))
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.playerController
                      .formatDuration(widget.playerController.position.value),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
                Text(
                  widget.playerController
                      .formatDuration(widget.playerController.duration.value),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildControls(Color dominantColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSecondaryButton(
                Icons.shuffle,
                () => widget.playerController.toggleShuffle(),
                widget.playerController.isShuffling,
              ),
              // _buildFavoriteButton(),
              _buildSecondaryButton(
                Icons.repeat,
                () => widget.playerController.toggleLoop(),
                widget.playerController.isLooping,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                  Icons.skip_previous, widget.playerController.skipToPrevious),
              _buildPlayButton(dominantColor),
              _buildControlButton(
                  Icons.skip_next, widget.playerController.skipToNext),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton(
      IconData icon, VoidCallback onTap, RxBool state) {
    return Obx(() => GestureDetector(
          onTap: () {
            onTap();
            HapticFeedback.lightImpact();
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: state.value
                  ? const Color(0xFF3A3A3A).withOpacity(0.3)
                  : Colors.transparent,
            ),
            child: Icon(
              icon,
              color: state.value ? Colors.white : Colors.white.withOpacity(0.6),
              size: 20,
            ),
          ),
        ));
  }

  // Widget _buildFavoriteButton() {
  //   return Obx(() {
  //     final song = widget.playerController.currentSong.value;
  //     final isFav =
  //         song != null && widget.favoriteController.isFavorite(song.path);

  //     return GestureDetector(
  //       onTap: song != null
  //           ? () {
  //               widget.favoriteController.toggleFavorite(song.path);
  //               HapticFeedback.lightImpact();
  //             }
  //           : null,
  //       child: Container(
  //         padding: const EdgeInsets.all(10),
  //         child: Icon(
  //           isFav ? Icons.favorite : Icons.favorite_border,
  //           color: isFav ? Colors.redAccent : Colors.white.withOpacity(0.6),
  //           size: 20,
  //         ),
  //       ),
  //     );
  //   );
  // }

  Widget _buildControlButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: () {
        onTap?.call();
        HapticFeedback.mediumImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildPlayButton(Color dominantColor) {
    return Obx(() => GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            widget.playerController.togglePlayPause();
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dominantColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              widget.playerController.isPlaying.value
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
          ),
        ));
  }
}
