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
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final SongController controller = Get.find<SongController>();
  final PlayerController playerController = Get.find<PlayerController>();

  late TabController _tabController;

  final List<({IconData icon, String? label})> _tabs = [
    (icon: Icons.music_note_rounded, label: 'Songs'),
    (icon: Icons.favorite_rounded, label: 'Favorites'),
    (icon: Icons.person_rounded, label: 'Artists'),
    (icon: Icons.album_rounded, label: 'Albums'),
  ];

  final List<Widget> _pages = [
    AllSongsPage(),
    FavoritesWidget(),
    ArtistsPage(),
    AlbumsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final isPlaying = playerController.currentSong.value != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.05,
                16,
                screenWidth * 0.05,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Row with greeting and actions
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Good ${_getGreeting()}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                    fontWeight: FontWeight.w400,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Music Player',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      _buildActionButton(
                        Icons.search_rounded,
                        () => Get.to(() => SearchPage()),
                      ),
                      const SizedBox(width: 12),
                      _buildMoreButton(),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Custom Tab Bar
                  _buildTabBar(),
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: Obx(() {
                final needsBottomPadding =
                    playerController.currentSong.value != null;
                return Container(
                  padding: EdgeInsets.only(bottom: needsBottomPadding ? 8 : 0),
                  child: TabBarView(
                    controller: _tabController,
                    children: _pages
                        .map(
                          (page) => Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.02),
                            child: page,
                          ),
                        )
                        .toList(),
                  ),
                );
              }),
            ),

            // Mini Player Section
            Obx(() => playerController.currentSong.value != null
                ? Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: MiniPlayer(),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Theme.of(context).colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Theme.of(context).colorScheme.onPrimary,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        labelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: _tabs
            .map((tab) => Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tab.icon, size: 16),
                      const SizedBox(width: 6),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildMoreButton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: PopupMenuButton<String>(
        onSelected: _handleMenuSelection,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).colorScheme.surface,
        elevation: 12,
        shadowColor: Colors.black.withOpacity(0.2),
        offset: const Offset(0, 8),
        child: Icon(
          Icons.more_vert_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        itemBuilder: (context) => [
          _buildMenuItem(Icons.refresh_rounded, 'Refresh Library', 'refresh'),
          const PopupMenuDivider(height: 1),
          _buildMenuItem(
              Icons.sort_by_alpha_rounded, 'Name (A-Z)', 'sort_name_asc'),
          _buildMenuItem(
              Icons.sort_by_alpha_rounded, 'Name (Z-A)', 'sort_name_desc'),
          _buildMenuItem(Icons.person_rounded, 'By Artist', 'sort_artist'),
          _buildMenuItem(
              Icons.access_time_rounded, 'Recently Added', 'sort_recent'),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      IconData icon, String text, String value) {
    return PopupMenuItem(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value) {
    final actions = {
      'refresh': () => controller.refreshSongs(),
      'sort_name_asc': () => controller.sortSongs(SortType.nameAsc),
      'sort_name_desc': () => controller.sortSongs(SortType.nameDesc),
      'sort_artist': () => controller.sortSongs(SortType.artist),
      'sort_recent': () => controller.sortSongs(SortType.recent),
    };

    final messages = {
      'refresh': 'Refreshing library...',
      'sort_name_asc': 'Sorted by name (A-Z)',
      'sort_name_desc': 'Sorted by name (Z-A)',
      'sort_artist': 'Sorted by artist',
      'sort_recent': 'Sorted by recently added',
    };

    actions[value]?.call();

    if (messages[value] != null) {
      _showSnackBar(messages[value]!);
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
    return switch (DateTime.now().hour) {
      >= 5 && < 12 => 'Morning',
      >= 12 && < 17 => 'Afternoon',
      >= 17 && < 22 => 'Evening',
      _ => 'Night',
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
