import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:musify/controllers/player_controller.dart';
import 'package:musify/controllers/favorite_controller.dart';
import 'package:musify/controllers/song_controller.dart';

class NowPlayingWidget extends StatelessWidget {
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

  Future<Map<String, Color>> _extractColors(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return _getDefaultColorMap();

    final data = byteData.buffer.asUint8List();
    final Map<int, int> colorCount = {};

    for (int i = 0; i < data.length; i += 16) {
      final r = data[i];
      final g = data[i + 1];
      final b = data[i + 2];
      final a = data[i + 3];

      if (a < 200) continue;

      final color = Color.fromARGB(255, r, g, b);
      final luminance = color.computeLuminance();

      if (luminance > 0.1 && luminance < 0.9) {
        final colorKey = (r << 16) | (g << 8) | b;
        colorCount[colorKey] = (colorCount[colorKey] ?? 0) + 1;
      }
    }

    if (colorCount.isEmpty) return _getDefaultColorMap();

    final dominantEntry =
        colorCount.entries.reduce((a, b) => a.value > b.value ? a : b);
    Color dominantColor = Color(0xFF000000 | dominantEntry.key);

    final hsl = HSLColor.fromColor(dominantColor);
    dominantColor = hsl
        .withSaturation((hsl.saturation * 0.6).clamp(0.3, 0.8))
        .withLightness(0.25)
        .toColor();

    final accentColor = hsl
        .withSaturation((hsl.saturation * 0.8).clamp(0.4, 1.0))
        .withLightness(0.35)
        .toColor();

    return {
      'dominant': dominantColor,
      'accent': accentColor,
    };
  }

  Map<String, Color> _getDefaultColorMap() {
    return {
      'dominant': const Color(0xFF2A2A2A),
      'accent': const Color(0xFF3A3A3A),
    };
  }

  Future<ui.Image> _loadImage(Uint8List data) async {
    try {
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Image loading error: $e');
      return await _loadImageDefault();
    }
  }

  Future<ui.Image> _loadImageDefault() async {
    final codec = await ui.instantiateImageCodec(
        (await rootBundle.load('assets/default_album_art.png'))
            .buffer
            .asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final albumSize = (size.width * 0.65).clamp(280.0, 320.0);

    return Obx(() {
      final currentSong = playerController.currentSong.value;
      final future =
          currentSong?.albumArt != null && currentSong!.albumArt!.isNotEmpty
              ? _loadImage(currentSong.albumArt!).then(_extractColors)
              : Future.value(_getDefaultColorMap());

      return FutureBuilder<Map<String, Color>>(
        future: future,
        builder: (context, snapshot) {
          final colors = snapshot.data ?? _getDefaultColorMap();
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
                      controller: scrollController,
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
                                  height:
                                      MediaQuery.of(context).padding.bottom),
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
        },
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
                playerController.currentSong.value?.title ?? 'No Song',
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
                playerController.currentSong.value?.artist ?? 'Unknown Artist',
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
      tag: 'album_art_${playerController.currentSong.value?.id ?? 'default'}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Obx(() {
            final albumArt = playerController.currentSong.value?.albumArt;
            return albumArt != null && albumArt.isNotEmpty
                ? Image.memory(albumArt,
                    fit: BoxFit.cover, width: size, height: size)
                : Container(
                    color: accentColor,
                    child: Icon(Icons.music_note,
                        size: size * 0.3, color: Colors.white54),
                  );
          }),
        ),
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Obx(() {
        final position =
            playerController.position.value.inMilliseconds.toDouble();
        final duration =
            playerController.duration.value.inMilliseconds.toDouble();
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
                    ? (v) =>
                        playerController.seek(Duration(milliseconds: v.toInt()))
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  playerController
                      .formatDuration(playerController.position.value),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
                Text(
                  playerController
                      .formatDuration(playerController.duration.value),
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
                () => playerController.toggleShuffle(),
                playerController.isShuffling,
              ),
              _buildFavoriteButton(),
              _buildSecondaryButton(
                Icons.repeat,
                () => playerController.toggleLoop(),
                playerController.isLooping,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                  Icons.skip_previous, playerController.playPrevious),
              _buildPlayButton(dominantColor),
              _buildControlButton(Icons.skip_next, playerController.playNext),
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

  Widget _buildFavoriteButton() {
    return Obx(() {
      final song = playerController.currentSong.value;
      final isFav = song != null && favoriteController.isFavorite(song.path);

      return GestureDetector(
        onTap: song != null
            ? () {
                favoriteController.toggleFavorite(song.path);
                HapticFeedback.lightImpact();
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.redAccent : Colors.white.withOpacity(0.6),
            size: 20,
          ),
        ),
      );
    });
  }

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
            playerController.isPlaying.value
                ? playerController.pause()
                : playerController.resume();
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
              playerController.isPlaying.value ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
          ),
        ));
  }
}
