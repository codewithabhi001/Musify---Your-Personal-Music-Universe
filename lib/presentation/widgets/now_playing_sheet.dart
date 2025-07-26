// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';
import '../../core/theme/app_theme.dart';
import '../../data/models/song_model.dart';
import '../blocs/player_bloc.dart';
import '../blocs/song_bloc.dart';
import 'album_art.dart' as album_art;

class NowPlayingSheet extends StatefulWidget {
  const NowPlayingSheet({super.key});

  @override
  State<NowPlayingSheet> createState() => _NowPlayingSheetState();
}

class _NowPlayingSheetState extends State<NowPlayingSheet> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      buildWhen: (previous, current) {
        // Rebuild only if currentSong, playbackState, or position changes
        if (previous is PlayerReady && current is PlayerReady) {
          return previous.currentSong?.id != current.currentSong?.id ||
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
        final position = state.position;
        final duration = state.duration ?? Duration.zero;

        // Update drag value when not dragging
        if (!_isDragging) {
          _dragValue = duration.inMilliseconds > 0
              ? position.inMilliseconds
                  .toDouble()
                  .clamp(0.0, duration.inMilliseconds.toDouble())
              : 0.0;
        }

        return Stack(
          children: [
            // Blurred background (album art or gradient)
            Positioned.fill(
              child: _buildBlurredBackground(song, context),
            ),
            // Overlay for readability
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.45),
              ),
            ),
            // Main content
            Positioned.fill(
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(height: 32),
                    // Drag Handle
                    Container(
                      margin: const EdgeInsets.only(top: 50, bottom: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Top Bar: Title, Artist, Menu
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Song Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  style: AppTheme.headlineSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song.artist,
                                  style: AppTheme.titleMedium.copyWith(
                                    color: Colors.white.withOpacity(0.85),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (song.album.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      song.album,
                                      style: AppTheme.bodySmall.copyWith(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Menu Icon
                          IconButton(
                            icon: Icon(Icons.more_vert_rounded,
                                color: Colors.white.withOpacity(0.9)),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Album Art
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.width * 0.8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: album_art.AlbumArtWidget(
                        song: song,
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.width * 0.8,
                        borderRadius: 24,
                        useFilePath: true,
                      ),
                    ),
                    // Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32.0, vertical: 8),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white.withOpacity(0.3),
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 7),
                              trackHeight: 4,
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14),
                            ),
                            child: Slider(
                              value: _dragValue,
                              min: 0.0,
                              max: duration.inMilliseconds > 0
                                  ? duration.inMilliseconds.toDouble()
                                  : 1.0,
                              onChanged: (value) {
                                setState(() {
                                  _isDragging = true;
                                  _dragValue = value;
                                });
                              },
                              onChangeEnd: (value) {
                                setState(() {
                                  _isDragging = false;
                                });
                                if (duration.inMilliseconds > 0) {
                                  context.read<PlayerBloc>().add(
                                        SeekTo(Duration(
                                            milliseconds: value.toInt())),
                                      );
                                }
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(
                                    Duration(milliseconds: _dragValue.toInt())),
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: AppTheme.bodySmall.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Row of icons (shuffle, favorite, playlist)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32.0, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: Icons.shuffle_rounded,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                            },
                            size: 26,
                            color: Colors.white.withOpacity(0.85),
                          ),
                          BlocBuilder<SongBloc, SongState>(
                            builder: (context, songState) {
                              final isFavorite = songState is SongsLoaded &&
                                  songState.songs.any(
                                      (s) => s.id == song.id && s.isFavorite);
                              return _buildControlButton(
                                icon: isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  context
                                      .read<SongBloc>()
                                      .add(ToggleFavorite(song.id));
                                },
                                size: 26,
                                color: isFavorite
                                    ? Colors.redAccent
                                    : Colors.white.withOpacity(0.85),
                              );
                            },
                          ),
                          _buildControlButton(
                            icon: Icons.queue_music_rounded,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                            },
                            size: 26,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ],
                      ),
                    ),
                    // Main Controls (prev, play/pause, next)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: Icons.skip_previous_rounded,
                            onPressed: () {
                              context.read<PlayerBloc>().add(SkipToPrevious());
                            },
                            size: 38,
                            color: Colors.white,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(40),
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  if (isPlaying) {
                                    context.read<PlayerBloc>().add(Pause());
                                  } else {
                                    context.read<PlayerBloc>().add(Resume());
                                  }
                                },
                                child: Container(
                                  width: 74,
                                  height: 74,
                                  alignment: Alignment.center,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      key: ValueKey('${song.id}_$isPlaying'),
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: 48,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _buildControlButton(
                            icon: Icons.skip_next_rounded,
                            onPressed: () {
                              context.read<PlayerBloc>().add(SkipToNext());
                            },
                            size: 38,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlurredBackground(Song song, BuildContext context) {
    return FutureBuilder<String?>(
      future: album_art.extractAlbumArtPath(song.path),
      builder: (context, snapshot) {
        Widget imageWidget;
        if (snapshot.hasData &&
            snapshot.data != null &&
            File(snapshot.data!).existsSync()) {
          imageWidget = Image.file(
            File(snapshot.data!),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return _buildGradientBackground(context);
            },
          );
        } else {
          imageWidget = _buildGradientBackground(context);
        }
        return ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
          child: imageWidget,
        );
      },
    );
  }

  Widget _buildGradientBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHigh,
            Theme.of(context).colorScheme.primaryContainer,
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: onPressed,
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: color ??
                Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            size: size,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
