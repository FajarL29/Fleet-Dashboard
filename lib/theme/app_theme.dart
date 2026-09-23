import 'package:flutter/material.dart';

class AppTheme {
  static const Color darkNavy = Color(0xFF1A1D24);
  static const Color slateGrey = Color(0xFF2A2D34);
  static const Color accentBlue = Color(0xFF007AFF);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8B8);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFE53935);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkNavy,
    primaryColor: accentBlue,
    cardColor: slateGrey,

    // Text Theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: textPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: textSecondary, fontSize: 14),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: slateGrey,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(color: textPrimary, size: 24),

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: darkNavy,
      elevation: 0,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// Palette for the redesigned (light) dashboard pages.
///
/// [AppTheme] above still holds the dark tokens the not-yet-migrated screens
/// use; these are the ones every light page reads from.
class AppColors {
  // Surfaces
  static const Color shell = Color(0xFFE8EDF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE3E8F1);
  static const Color tileBackground = Color(0xFFF2F5FA);
  static const Color tileBorder = Color(0xFFE7ECF4);
  static const Color divider = Color(0xFFEDF0F6);
  static const Color skeleton = Color(0xFFE7EBF3);

  // Text
  static const Color textPrimary = Color(0xFF0F1D3D);
  static const Color textSecondary = Color(0xFF5B6B87);
  static const Color textMuted = Color(0xFF98A2B5);

  // Accents
  /// Solid navy used by primary buttons, filter chips and pagination.
  static const Color navy = Color(0xFF12386A);
  static const Color blue = Color(0xFF2563EB);
  static const Color blueSoft = Color(0xFFE3EDFD);
  static const Color green = Color(0xFF22C55E);
  static const Color greenSoft = Color(0xFFE7F7EE);
  static const Color greenText = Color(0xFF15803D);
  static const Color red = Color(0xFFEF4444);
  static const Color redSoft = Color(0xFFFDE3E4);
  static const Color redText = Color(0xFFD92D20);
  static const Color amber = Color(0xFFF59E0B);
  static const Color amberSoft = Color(0xFFFDF3D7);
  static const Color amberText = Color(0xFFB45309);
  static const Color yellow = Color(0xFFFBBF24);

  /// Idle vehicles on the map, matching the marker colour in [Vehicle].
  static const Color sky = Color(0xFF38BDF8);

  /// Drop shadow under floating surfaces such as the account menu.
  static Color get menuShadow => textPrimary.withValues(alpha: 0.16);

  static List<BoxShadow> get cardShadow => const [
    BoxShadow(color: Color(0x0D101B33), blurRadius: 10, offset: Offset(0, 2)),
  ];
}

/// Air Quality Index bands, shared by the legend, the map route and the
/// reading badges.
class AppAqiColors {
  static const Color good = Color(0xFF4ADE80);
  static const Color moderate = Color(0xFFFBBF24);
  static const Color unhealthy = Color(0xFFF97316);
  static const Color veryUnhealthy = Color(0xFFE11D8F);
  static const Color hazardous = Color(0xFF9D3BC4);
}

/// Dark basemap the light pages' map cards render on.
///
/// Esri's Dark Gray Canvas is served without an API key. CARTO's dark_all was
/// used before and now returns "API KEY REQUIRED" placeholder tiles.
class AppMapStyle {
  /// Plain OpenStreetMap: the same basemap every map in the app uses, so a
  /// vehicle looks the same on Overview, Live Tracking and Air Quality.
  static const String tileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> tileSubdomains = <String>[];

  /// Deepest zoom this basemap actually ships; past it the tiles are upscaled
  /// rather than coming back empty.
  static const int tileMaxNativeZoom = 19;

  /// Required by the tile providers' terms of use.
  static const String tileAttribution = '© OpenStreetMap contributors';

  /// No wash over the basemap: the tint existed to darken the old dark-grey
  /// Esri tiles, and over a light basemap it only muddies the streets.
  static const Color? tint = null;

  /// Ground colour behind the tiles while they load.
  static const Color background = AppColors.tileBackground;

  /// Backdrop for the legend / status chips floating on the map.
  static const Color overlayBackground = Color(0xF2FFFFFF);

  /// Backdrop for the small buttons floating on the map.
  static const Color buttonBackground = Color(0xE6FFFFFF);
}
