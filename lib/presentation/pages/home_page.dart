import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/song_bloc.dart';

import '../widgets/song_list.dart';
import '../widgets/mini_player.dart';

import '../widgets/favorites_list.dart';
import '../widgets/artist_list.dart';
import '../widgets/album_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  int _currentIndex = 0;
  bool _isSearchExpanded = false;

  final List<Widget> _pages = [
    const SongList(),
    const FavoritesList(),
    const ArtistList(),
    const AlbumList(),
  ];

  final List<Map<String, dynamic>> _navItems = [
    {'text': 'Songs', 'icon': Icons.music_note_rounded, 'section': 'songs'},
    {'text': 'Favorites', 'icon': Icons.favorite_rounded, 'section': 'favorites'},
    {'text': 'Artists', 'icon': Icons.person_rounded, 'section': 'artists'},
    {'text': 'Albums', 'icon': Icons.album_rounded, 'section': 'albums'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _pages.length, vsync: this);
    
    // Load songs when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SongBloc>().add(LoadSongs());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Column(
        children: [
          // App Bar with Search
          _buildAppBar(),
          
          // Navigation Tabs
          _buildNavigationTabs(),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _pages,
            ),
          ),
          
          // Mini Player
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: AppTheme.mediumAnimation,
        child: _isSearchExpanded ? _buildSearchBar() : _buildAppBarContent(),
      ),
    );
  }

  Widget _buildAppBarContent() {
    return Row(
      children: [
        // App Icon with Gradient
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppTheme.getSectionGradient('songs'),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.music_note_rounded,
            size: 24,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        
        // App Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                AppConstants.appTagline,
                style: AppTheme.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        
        // Action Buttons
        Row(
          children: [
            // Search Button
            IconButton(
              onPressed: () {
                setState(() {
                  _isSearchExpanded = !_isSearchExpanded;
                });
              },
              icon: Icon(
                Icons.search_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                size: 22,
              ),
            ),
            
            // Refresh Button
            IconButton(
              onPressed: () {
                context.read<SongBloc>().add(RefreshSongs());
              },
              icon: BlocBuilder<SongBloc, SongState>(
                builder: (context, state) {
                  if (state is SongsLoaded && state.isLoading) {
                    return SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }
                  return Icon(
                    Icons.refresh_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    size: 22,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        // Back Button
        IconButton(
          onPressed: () {
            setState(() {
              _isSearchExpanded = false;
              _searchController.clear();
              context.read<SongBloc>().add(SearchSongs(''));
            });
          },
          icon: Icon(
            Icons.arrow_back_rounded,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        
        // Search TextField
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) {
                context.read<SongBloc>().add(SearchSongs(value));
              },
              decoration: InputDecoration(
                hintText: 'Search songs, artists, albums...',
                hintStyle: AppTheme.bodyMedium.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          context.read<SongBloc>().add(SearchSongs(''));
                        },
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          size: 18,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: AppTheme.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationTabs() {
    return BlocBuilder<SongBloc, SongState>(
      builder: (context, state) {
        int allCount = 0, favCount = 0, artistCount = 0, albumCount = 0;
        if (state is SongsLoaded) {
          allCount = state.songs.length;
          favCount = state.favorites.length;
          artistCount = state.artists.length;
          albumCount = state.albums.length;
        }
        final counts = [allCount, favCount, artistCount, albumCount];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: _navItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = _currentIndex == index;
              final color = isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    _tabController.animateTo(index);
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: AppTheme.mediumAnimation,
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'],
                          size: isSelected ? 22 : 20,
                          color: color,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['text'],
                          style: AppTheme.labelSmall.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            counts[index].toString(),
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}