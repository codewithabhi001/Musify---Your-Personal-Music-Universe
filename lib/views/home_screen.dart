import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:musify/controllers/player_controller.dart';
import 'package:musify/controllers/song_controller.dart';
import 'package:musify/model/song_model.dart';
import 'package:musify/views/all_song.dart';
import 'package:musify/views/favorites_screen.dart';
import 'package:musify/views/mini_player_screen.dart';
import 'package:musify/views/search_page.dart';
import 'package:musify/views/albums_page.dart';
import 'package:musify/views/artists_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SongController controller = Get.find<SongController>();
  final PlayerController playerController = Get.find<PlayerController>();

  late final PageController _pageController;
  int _currentIndex = 0;
  late final String _greeting = _getGreeting(); // FIXED

  final List<Widget> _pages = [
    AllSongsPage(),
    FavoritesWidget(),
    ArtistsPage(),
    AlbumsPage(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'text': 'Songs', 'icon': Icons.music_note_rounded},
    {'text': 'Favorites', 'icon': Icons.favorite_rounded},
    {'text': 'Artists', 'icon': Icons.person_rounded},
    {'text': 'Albums', 'icon': Icons.album_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      final newIndex = _pageController.page?.round() ?? 0;
      if (newIndex != _currentIndex) {
        setState(() => _currentIndex = newIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(
                      Get.width * 0.05, 10, Get.width * 0.05, 15),
                  constraints: const BoxConstraints(minHeight: 80),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good $_greeting',
                                style: TextStyle(
                                  fontSize: Get.width * 0.05,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                'Music Player',
                                style: TextStyle(
                                  fontSize: Get.width * 0.08,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildActionButton(
                                Icons.search_rounded,
                                () => Get.to(() => SearchPage()),
                              ),
                              const SizedBox(width: 8),
                              _buildMoreButton(context),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildNavigationBar(context),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    final isPlaying =
                        playerController.currentSong.value != null;
                    return PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      children: _pages.map((page) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: isPlaying ? 60 : 10),
                          child: page,
                        );
                      }).toList(),
                    );
                  }),
                ),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MiniPlayer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _navItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = _currentIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _pageController.jumpToPage(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected ? null : Colors.transparent,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'],
                        size: 16,
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item['text'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          size: 24,
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert_rounded,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          size: 24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        color: Theme.of(context).colorScheme.surface,
        onSelected: _handleMenuSelection,
        itemBuilder: (context) => [
          _buildPopupItem(Icons.refresh_rounded, 'Refresh Library', 'refresh'),
          const PopupMenuDivider(),
          _buildPopupItem(
              Icons.sort_by_alpha_rounded, 'Name (A-Z)', 'sort_name_asc'),
          _buildPopupItem(
              Icons.sort_by_alpha_rounded, 'Name (Z-A)', 'sort_name_desc'),
          _buildPopupItem(Icons.person_rounded, 'By Artist', 'sort_artist'),
          _buildPopupItem(
              Icons.access_time_rounded, 'Recently Added', 'sort_recent'),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupItem(
      IconData icon, String text, String value) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
            child: Icon(icon,
                size: 18, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'refresh':
        controller.refreshSongs();
        _showSnackBar('Refreshing library...');
        break;
      case 'sort_name_asc':
        controller.sortSongs(SortType.nameAsc);
        _showSnackBar('Sorted by name (A-Z)');
        break;
      case 'sort_name_desc':
        controller.sortSongs(SortType.nameDesc);
        _showSnackBar('Sorted by name (Z-A)');
        break;
      case 'sort_artist':
        controller.sortSongs(SortType.artist);
        _showSnackBar('Sorted by artist');
        break;
      case 'sort_recent':
        controller.sortSongs(SortType.recent);
        _showSnackBar('Sorted by recently added');
        break;
    }
  }

  void _showSnackBar(String message) {
    Get.snackbar(
      '',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      colorText: Theme.of(context).colorScheme.onSurface,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: const Duration(seconds: 2),
      titleText: const SizedBox.shrink(),
      messageText: Text(
        message,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 22) return 'Evening';
    return 'Night';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
