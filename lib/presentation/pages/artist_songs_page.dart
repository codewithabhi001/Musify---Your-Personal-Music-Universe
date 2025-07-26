import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/song_model.dart';
import '../blocs/player_bloc.dart';
import '../blocs/song_bloc.dart';
import '../widgets/album_art.dart';
import '../widgets/song_list.dart';
import 'dart:io';

class ArtistSongsPage extends StatelessWidget {
  final dynamic artist;
  const ArtistSongsPage({Key? key, required this.artist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(artist.name),
        centerTitle: true,
      ),
      body: BlocBuilder<SongBloc, SongState>(
        builder: (context, state) {
          if (state is! SongsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final songs = state.songs.where((s) => s.artist == artist.name).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: (artist.imagePath != null && artist.imagePath.isNotEmpty)
                          ? Image.file(
                              File(artist.imagePath),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Theme.of(context).colorScheme.surface,
                              child: Icon(Icons.person_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(artist.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('${artist.songCount} songs', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: songs.length,
                  separatorBuilder: (context, i) => Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.15)),
                  itemBuilder: (context, i) {
                    final song = songs[i];
                    return ListTile(
                      leading: AlbumArtWidget(song: song, width: 44, height: 44),
                      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(song.album, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                      onTap: () {
                        context.read<PlayerBloc>().add(PlaySong(song, playlist: songs, initialIndex: i));
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
} 