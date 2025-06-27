import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musify/controllers/song_controller.dart';
import 'package:musify/views/song_list_page.dart';

class AlbumsPage extends StatelessWidget {
  final SongController controller = Get.find<SongController>();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final uniqueAlbums = controller.songs
            .map((s) => s.album)
            .whereType<String>()
            .toSet()
            .toList();

        if (uniqueAlbums.isEmpty) {
          return _buildEmptyState(Icons.album, 'No albums found');
        }

        return ListView.separated(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: uniqueAlbums.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final album = uniqueAlbums[index];
            final songsInAlbum = controller.getSongsByAlbum(album);
            if (songsInAlbum.isEmpty) return const SizedBox.shrink();

            return Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: controller.getAlbumArt(
                    width: 50,
                    height: 50,
                    song: songsInAlbum.first,
                  ),
                ),
                title: Text(
                  album,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${songsInAlbum.length} song${songsInAlbum.length > 1 ? 's' : ''}',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6)),
                ),
                onTap: () {
                  Get.to(() => SongListPage(
                        title: 'Songs in $album',
                        songs: songsInAlbum,
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
