class AppConstants {
  // App Info
  static const String appName = 'Musify';
  static const String appTagline = 'Your Personal Music Universe';
  static const String appVersion = '0.1.0';
  
  // Navigation
  static const String splashRoute = '/';
  static const String homeRoute = '/home';
  static const String searchRoute = '/search';
  static const String songListRoute = '/song-list';
  static const String nowPlayingRoute = '/now-playing';
  
  // Storage Keys
  static const String favoritesKey = 'favorites';
  static const String themeKey = 'theme_mode';
  static const String sortTypeKey = 'sort_type';
  static const String lastPlayedSongKey = 'last_played_song';
  
  // Audio
  static const Duration seekDuration = Duration(seconds: 10);
  static const Duration fadeDuration = Duration(milliseconds: 300);
  
  // UI
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double iconSize = 24.0;
  
  // Animation
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(milliseconds: 2500);
  
  // File Extensions
  static const List<String> supportedAudioFormats = [
    '.mp3',
    '.m4a',
    '.wav',
    '.flac',
    '.aac',
    '.ogg',
  ];
} 