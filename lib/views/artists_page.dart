import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/song_controller.dart';
import 'package:musify/views/song_list_page.dart';
import 'dart:typed_data';
import 'package:musify/services/album_art_service.dart';

class ArtistsPage extends GetView<SongController> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final uniqueArtists = controller.songs
            .map((s) => s.artist)
            .whereType<String>()
            .toSet()
            .toList();

        if (uniqueArtists.isEmpty) {
          return _buildEmptyState(Icons.person, 'No artists found');
        }

        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: uniqueArtists.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final artist = uniqueArtists[index];
            final songsByArtist = controller.getSongsByArtist(artist);
            if (songsByArtist.isEmpty) return const SizedBox.shrink();

            return Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: FutureBuilder<Uint8List?>(
                  future: AlbumArtService().getAlbumArt(songsByArtist.first.path),
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
                title: Text(
                  artist,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${songsByArtist.length} song${songsByArtist.length > 1 ? 's' : ''}',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6)),
                ),
                onTap: () {
                  Get.to(() => SongListPage(
                        title: 'Songs by $artist',
                        songs: songsByArtist,
                      ));
                },
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }
}
