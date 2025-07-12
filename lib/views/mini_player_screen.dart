import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musify/controllers/player_controller.dart';
import 'package:musify/controllers/song_controller.dart';
import 'now_playing_widget.dart';
import 'dart:ui';
import 'package:musify/services/album_art_service.dart';

class MiniPlayer extends GetView<PlayerController> {
  final SongController songController =
      Get.find<SongController>(); // Non-nullable, assuming initialized

  MiniPlayer({super.key});

  void _showNowPlayingSheet(BuildContext context) {
    if (controller == null ||
        controller!.currentSong.value == null) {
      Get.snackbar('Error', 'No song is playing');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 1.0,
          minChildSize: 0.3,
          maxChildSize: 1.0,
          snap: true,
          snapSizes: const [0.3, 1.0],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: NowPlayingWidget(
                favoriteController: Get.find(),
                songController: songController,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller == null ||
          controller!.currentSong.value == null) {
        return const SizedBox.shrink();
      }

      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 65,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.15),
                ],
              ),
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showNowPlayingSheet(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Hero(
                        tag:
                            'album_art_${controller!.currentSong.value!.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FutureBuilder<Uint8List?>(
                            future: AlbumArtService().getAlbumArt(controller!.currentSong.value!.path),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey.shade800,
                                  child: Icon(Icons.music_note, color: Colors.white, size: 28),
                                );
                              }
                              if (snapshot.hasData && snapshot.data != null) {
                                return Image.memory(
                                  snapshot.data!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey.shade800,
                                    child: Icon(Icons.music_note, color: Colors.white, size: 28),
                                  ),
                                );
                              }
                              return Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey.shade800,
                                child: Icon(Icons.music_note, color: Colors.white, size: 28),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller!.currentSong.value!.title,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (controller!.currentSong.value!.artist !=
                                null)
                              Text(
                                controller!.currentSong.value!.artist!,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                              ),
                          ],
                        ),
                      ),
                      _buildControlButton(context, Icons.skip_previous,
                          controller!.playPrevious),
                      _buildControlButton(
                        context,
                        controller!.isPlaying.value
                            ? Icons.pause
                            : Icons.play_arrow,
                        () => controller!.isPlaying.value
                            ? controller!.pause()
                            : controller!.resume(),
                        isPlayButton: true,
                      ),
                      _buildControlButton(
                          context, Icons.skip_next, controller!.playNext),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildControlButton(
    BuildContext context,
    IconData icon,
    VoidCallback? onPressed, {
    bool isPlayButton = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: isPlayButton ? 28 : 24,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
