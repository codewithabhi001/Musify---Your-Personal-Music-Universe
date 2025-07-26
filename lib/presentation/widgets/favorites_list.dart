import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/song_model.dart';
import '../blocs/song_bloc.dart';
import '../blocs/player_bloc.dart';
import 'album_art.dart';

class FavoritesList extends StatelessWidget {
  const FavoritesList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SongBloc, SongState>(
      builder: (context, state) {
        if (state is SongsLoaded) {
          final favorites = state.favorites;
          
          if (favorites.isEmpty) {
            return _buildEmptyState(context);
          }
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final song = favorites[index];
              return _FavoriteSongTile(song: song);
            },
          );
        }
        
        return _buildLoadingState(context);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No favorites yet',
            style: AppTheme.headlineSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart icon on any song to add it to favorites',
            style: AppTheme.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _FavoriteSongTile extends StatelessWidget {
  final dynamic song;

  const _FavoriteSongTile({required this.song});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, playerState) {
        final isCurrentSong = playerState is PlayerReady && 
                             playerState.currentSong?.id == song.id;
        final isPlaying = isCurrentSong && 
                         playerState.playbackState == PlaybackState.playing;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isCurrentSong ? 4 : 1,
          color: isCurrentSong 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.transparent,
              ),
              child: AlbumArtWidget(
                song: song,
                width: 40,
                height: 40,
                borderRadius: 6,
              ),
            ),
            title: Text(
              song.title,
              style: AppTheme.bodyMedium.copyWith(
                fontWeight: isCurrentSong ? FontWeight.w600 : FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${song.artist ?? "Unknown"}${song.album != null && song.album.isNotEmpty ? " • ${song.album}" : ""}',
              style: AppTheme.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Favorite Button
                IconButton(
                  onPressed: () {
                    context.read<SongBloc>().add(ToggleFavorite(song.id));
                  },
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.favorite_rounded,
                      key: ValueKey(song.isFavorite),
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
                
                // Play Button
                IconButton(
                  onPressed: () => _playSong(context, song),
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
            onTap: () => _playSong(context, song),
          ),
        );
      },
    );
  }

  void _playSong(BuildContext context, dynamic song) {
    final playerBloc = context.read<PlayerBloc>();
    final playerState = playerBloc.state;
    
    if (playerState is! PlayerReady) {
      playerBloc.add(InitializePlayer());
      Future.delayed(const Duration(milliseconds: 200), () {
        playerBloc.add(PlaySong(song));
      });
    } else {
      if (playerState.currentSong?.id == song.id) {
        if (playerState.playbackState == PlaybackState.playing) {
          playerBloc.add(Pause());
        } else {
          playerBloc.add(Resume());
        }
      } else {
        playerBloc.add(PlaySong(song));
      }
    }
  }
} 