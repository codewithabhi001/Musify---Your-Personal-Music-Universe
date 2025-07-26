import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class AppTheme {
  // Enhanced color palette
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color primaryBlueDark = Color(0xFF0D47A1);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color surfaceLight = Color(0xFFF8FAFC);
  static const Color surfaceDark = Color(0xFF0F172A);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B);
  
  static ThemeData get lightTheme {
    return FlexThemeData.light(
      scheme: FlexScheme.deepBlue,
      useMaterial3: true,
      appBarElevation: 0,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 0,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
      
        defaultRadius: 16,
        inputDecoratorRadius: 16,
        chipRadius: 20,
        dialogRadius: 20,
        cardRadius: 16,
        elevatedButtonRadius: 16,
        outlinedButtonRadius: 16,
        filledButtonRadius: 16,
        bottomSheetRadius: 20,
        snackBarRadius: 16,
        navigationBarElevation: 0,
        navigationBarHeight: 70,
        navigationBarOpacity: 0.95,
        bottomNavigationBarElevation: 8,
        tabBarItemSchemeColor: SchemeColor.primary,
        appBarScrolledUnderElevation: 4,
        cardElevation: 2,
        elevatedButtonElevation: 4,
        popupMenuRadius: 12,
        menuRadius: 12,
        timePickerDialogRadius: 20,
        datePickerDialogRadius: 20,
        tooltipRadius: 8,
        searchBarRadius: 24,
   
        sliderValueTinted: true,
        switchThumbFixedSize: true,
        toggleButtonsRadius: 16,
        segmentedButtonRadius: 20,
        unselectedToggleIsColored: true,
        fabUseShape: true,
        fabAlwaysCircular: true,
        fabSchemeColor: SchemeColor.primary,
        drawerRadius: 16,
        drawerWidth: 280,
        bottomSheetElevation: 8,
        navigationRailElevation: 0,
        navigationRailOpacity: 0.95,
        navigationRailUseIndicator: true,
        navigationRailLabelType: NavigationRailLabelType.selected,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'Inter',
    ).copyWith(
      // Custom enhancements
      scaffoldBackgroundColor: surfaceLight,
      cardColor: cardLight,
      shadowColor: Colors.black.withOpacity(0.08),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.15),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: Colors.grey.withOpacity(0.12),
      ),
    );
  }

  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      scheme: FlexScheme.bahamaBlue,
      useMaterial3: true,
      appBarElevation: 10,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 20,
      subThemesData: const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        useTextTheme: true,
        defaultRadius: 16,
        inputDecoratorRadius: 16,
        chipRadius: 20,
        dialogRadius: 20,
        cardRadius: 16,
        elevatedButtonRadius: 16,
        outlinedButtonRadius: 16,
        filledButtonRadius: 16,
        bottomSheetRadius: 20,
        snackBarRadius: 16,
        navigationBarElevation: 0,
        navigationBarHeight: 70,
        navigationBarOpacity: 0.95,
        bottomNavigationBarElevation: 8,
        tabBarItemSchemeColor: SchemeColor.primary,
        appBarScrolledUnderElevation: 4,
        cardElevation: 4,
        elevatedButtonElevation: 6,
        popupMenuRadius: 12,
        menuRadius: 12,
        timePickerDialogRadius: 20,
        datePickerDialogRadius: 20,
        tooltipRadius: 8,
        searchBarRadius: 24,
    
        sliderValueTinted: true,
        switchThumbFixedSize: true,
        toggleButtonsRadius: 16,
        segmentedButtonRadius: 20,
        unselectedToggleIsColored: true,
        fabUseShape: true,
        fabAlwaysCircular: true,
        fabSchemeColor: SchemeColor.primary,
        drawerRadius: 16,
        drawerWidth: 280,
        bottomSheetElevation: 12,
        navigationRailElevation: 0,
        navigationRailOpacity: 0.95,
        navigationRailUseIndicator: true,
        navigationRailLabelType: NavigationRailLabelType.selected,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      fontFamily: 'Inter',
    ).copyWith(
      // Custom enhancements for dark theme
      scaffoldBackgroundColor: surfaceDark,
      cardColor: cardDark,
      shadowColor: Colors.black.withOpacity(0.3),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 4,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: Colors.white.withOpacity(0.08),
      ),
    );
  }

  // Enhanced section colors with gradients
  static const Map<String, List<Color>> sectionGradients = {
    'songs': [Color(0xFF1E88E5), Color(0xFF42A5F5)],
    'favorites': [Color(0xFFE53935), Color(0xFFEF5350)],
    'artists': [Color(0xFF43A047), Color(0xFF66BB6A)],
    'albums': [Color(0xFF8E24AA), Color(0xFFAB47BC)],
    'playlists': [Color(0xFFFF8F00), Color(0xFFFFB74D)],
    'genres': [Color(0xFF00ACC1), Color(0xFF26C6DA)],
  };

  // Enhanced section colors
  static const Map<String, Color> sectionColors = {
    'songs': Color(0xFF1E88E5),
    'favorites': Color(0xFFE53935),
    'artists': Color(0xFF43A047),
    'albums': Color(0xFF8E24AA),
    'playlists': Color(0xFFFF8F00),
    'genres': Color(0xFF00ACC1),
  };

  // Enhanced text styles with better typography
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
    height: 1.25,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.15,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.4,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // Custom text styles for music app
  static const TextStyle songTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle artistName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle albumName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle duration = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.3,
  );

  static const TextStyle nowPlayingTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle nowPlayingArtist = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.3,
  );

  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Custom dimensions
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  static const double defaultRadius = 16.0;
  static const double smallRadius = 8.0;
  static const double largeRadius = 24.0;

  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // Helper methods
  static LinearGradient getSectionGradient(String section) {
    final colors = sectionGradients[section] ?? sectionGradients['songs']!;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  static Color getSectionColor(String section) {
    return sectionColors[section] ?? sectionColors['songs']!;
  }

  static BoxShadow getCardShadow({bool isDark = false}) {
    return BoxShadow(
      color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
      blurRadius: isDark ? 12 : 8,
      offset: const Offset(0, 4),
    );
  }

  static BoxShadow getElevatedShadow({bool isDark = false}) {
    return BoxShadow(
      color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.15),
      blurRadius: isDark ? 16 : 12,
      offset: const Offset(0, 6),
    );
  }
}