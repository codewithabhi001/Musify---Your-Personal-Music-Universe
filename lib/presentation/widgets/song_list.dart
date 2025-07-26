import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/song_bloc.dart';
import '../blocs/player_bloc.dart';
import 'album_art.dart';
import '../../data/models/song_model.dart' show PlaybackState;

class SongList extends StatelessWidget {
  const SongList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SongBloc, SongState>(
      builder: (context, state) {
        if (state is SongsLoaded && state.filteredSongs.isNotEmpty) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.filteredSongs.length,
            itemBuilder: (context, index) {
              final song = state.filteredSongs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.read<PlayerBloc>().add(
                          PlaySong(song,
                              playlist: state.filteredSongs,
                              initialIndex: index),
                        ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          // Album Art
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: AlbumArtWidget(
                                song: song, width: 48, height: 48),
                          ),
                          const SizedBox(width: 14),
                          // Song Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${song.artist} • ${song.album}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.6),
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Play Icon or Indicator
                          BlocBuilder<PlayerBloc, PlayerState>(
                            builder: (context, playerState) {
                              final isPlaying = playerState is PlayerReady &&
                                  playerState.currentSong?.id == song.id &&
                                  playerState.playbackState ==
                                      PlaybackState.playing;
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                switchInCurve: Curves.easeIn,
                                switchOutCurve: Curves.easeOut,
                                child: isPlaying
                                    ? Icon(Icons.equalizer_rounded,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        key:
                                            ValueKey('icon_${song.id}_playing'))
                                    : Icon(Icons.play_arrow_rounded,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.5),
                                        key: ValueKey(
                                            'icon_${song.id}_not_playing')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        }
        if (state is SongsLoaded && state.filteredSongs.isEmpty) {
          return Center(
            child: Text('No songs found',
                style: Theme.of(context).textTheme.bodyMedium),
          );
        }
        // Show loader while loading
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
