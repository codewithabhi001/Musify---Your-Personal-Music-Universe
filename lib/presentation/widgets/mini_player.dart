import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


import '../../data/models/song_model.dart';
import '../blocs/player_bloc.dart';
import 'album_art.dart';
import 'now_playing_sheet.dart';
import 'dart:io';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) {
        if (previous is PlayerReady && current is PlayerReady) {
          return previous.currentSong != current.currentSong ||
                 previous.playbackState != current.playbackState ||
                 previous.position != current.position;
        }
        return true;
      },
      builder: (context, state) {
        if (state is! PlayerReady || state.currentSong == null) {
          return const SizedBox.shrink();
        }

        final song = state.currentSong!;
        final isPlaying = state.playbackState == PlaybackState.playing;
        final albumArtPath = song.albumArtPath;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 360;
            final iconSize = isSmallScreen ? 18.0 : 20.0;
            final playPauseIconSize = isSmallScreen ? 24.0 : 26.0;
            final albumArtSize = isSmallScreen ? 48.0 : 52.0;

            return GestureDetector(
              onTap: () => _showNowPlayingSheet(context),
              child: Container(
                height: 75,
                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Background Image with Blur Effect
                      _buildBackgroundImage(albumArtPath, context),
                      
                      // Strong glassmorphism overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.white.withOpacity(0.05),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                      ),
                      

                      
                      // Main content
                      Positioned.fill(
                        child: Row(
                          children: [
                            // Album Art
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: AlbumArtWidget(
                                    song: song,
                                    key: ValueKey(song.id),
                                    width: albumArtSize,
                                    height: albumArtSize,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Song Info - Flexible to take available space
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8, right: 8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: isSmallScreen ? 13 : 14,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      song.artist,
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                                        fontSize: isSmallScreen ? 11 : 12,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Controls - Fixed width container
                            Container(
                              width: isSmallScreen ? 130 : 140,
                              padding: const EdgeInsets.only(right: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildControlButton(
                                    context: context,
                                    icon: Icons.skip_previous_rounded,
                                    onPressed: () => context.read<PlayerBloc>().add(SkipToPrevious()),
                                    size: iconSize,
                                    isPrimary: false,
                                  ),
                                  _buildControlButton(
                                    context: context,
                                    icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                    onPressed: () {
                                      if (isPlaying) {
                                        context.read<PlayerBloc>().add(Pause());
                                      } else {
                                        context.read<PlayerBloc>().add(Resume());
                                      }
                                    },
                                    size: playPauseIconSize,
                                    isPrimary: true,
                                    key: ValueKey('${song.id}_$isPlaying'),
                                  ),
                                  _buildControlButton(
                                    context: context,
                                    icon: Icons.skip_next_rounded,
                                    onPressed: () => context.read<PlayerBloc>().add(SkipToNext()),
                                    size: iconSize,
                                    isPrimary: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBackgroundImage(String? albumArtPath, BuildContext context) {
    if (albumArtPath != null && albumArtPath.isNotEmpty && File(albumArtPath).existsSync()) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image - stretched to fill
            Image.file(
              File(albumArtPath),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            // Strong blur filter overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),
            // Second blur layer for stronger effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
              ),
            ),
          ],
        ),
      );
    } else {
      // Default background when no image
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface.withOpacity(0.9),
              Theme.of(context).colorScheme.surface.withOpacity(0.7),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildControlButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    required bool isPrimary,
    Key? key,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: isPrimary 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
              : Colors.white.withOpacity(0.1),
            border: isPrimary
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                )
              : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            key: key,
            color: isPrimary 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            size: size,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNowPlayingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const NowPlayingSheet(),
    );
  }
}