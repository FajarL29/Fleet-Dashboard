import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Palette for the sign-in and sign-up pages.
///
/// Every token resolves to a colour already in [AppColors], so the auth pages
/// and the dashboard behind them read as one product instead of two. Add a
/// token here rather than hard-coding a hex value in a widget.
class AuthColors {
  const AuthColors._();

  // Text
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;

  /// Supporting copy, helper icons and the footer line.
  static const Color muted = AppColors.textMuted;

  /// Hint text inside an empty field. Deliberately the same as [muted]: a
  /// hint is not content, so it must not compete with a filled-in value.
  static const Color placeholder = AppColors.textMuted;

  // Brand
  /// Primary action colour: the sign-in button, links and focused fields.
  static const Color brandBlue = AppColors.blue;

  /// The deeper navy used for brand marks and the illustration's vehicles.
  static const Color brandBlueDark = AppColors.navy;

  /// Tinted fill behind the logo mark and other blue-on-blue badges.
  static const Color brandBlueSoft = AppColors.blueSoft;

  /// Halo cast by the brand-blue map pin. A const literal because the
  /// [BoxShadow]s that use it sit inside const decorations.
  static const Color brandGlow = Color(0x332563EB);

  // Surfaces
  /// Ground of the left-hand marketing panel.
  static const Color brandPanel = AppColors.shell;

  /// Ground the whole auth page sits on, behind the rounded panel and the
  /// form column.
  static const Color pageBackground = Color(0xFFF7FAFD);

  /// The strip along the bottom of the form column.
  static const Color footer = AppColors.tileBackground;

  /// The oversized circle lightening the top-right of the brand panel.
  static const Color panelHighlight = Color(0xFFFAFCFF);

  /// Resting field and card outlines.
  static const Color border = AppColors.cardBorder;

  /// Outlines that must stay visible against a tinted fill — checkboxes and
  /// the SSO button — where [border] would disappear.
  static const Color borderStrong = Color(0xFFCBD5E4);

  // Status
  static const Color success = AppColors.green;

  /// Ground and outline behind a confirmation banner.
  static const Color successSoft = AppColors.greenSoft;
  static const Color successText = AppColors.greenText;

  /// Error text and the high-risk badge. The darker red of the pair, so it
  /// still passes contrast as small text on white.
  static const Color danger = AppColors.redText;

  /// Tinted ground behind an inline error message.
  static const Color dangerSoft = AppColors.redSoft;

  // Illustration
  /// Dotted grid behind the brand panel's map.
  static const Color mapGrid = Color(0xFFC7D3E4);

  /// The route line traced across that map.
  static const Color route = AppColors.blue;

  // The animated scene on the auth pages' left panel, sky down to asphalt.
  /// Top of the sky gradient.
  static const Color skyHigh = Color(0xFFD9EAFB);

  /// Sky at the horizon, where it washes out behind the city.
  static const Color skyLow = Color(0xFFEFF6FD);

  /// Distant towers along the horizon.
  static const Color skyline = Color(0xFF5C7BA6);

  /// Ground at the horizon.
  static const Color groundFar = Color(0xFFE7EFF8);

  /// Ground in the foreground, nearest the viewer.
  static const Color groundNear = Color(0xFFD5E3F2);

  /// The road surface.
  static const Color asphalt = Color(0xFF44576F);

  /// The darkest of the three vehicle tints.
  static const Color routeDeep = Color(0xFF1E4E8C);
}

/// The subset of [AuthColors] the register page's left panel reads.
///
/// It exists so the register widgets keep their own vocabulary while still
/// drawing from the single palette above.
class AuthTheme {
  const AuthTheme._();

  static const Color primaryBlue = AuthColors.brandBlue;
  static const Color darkBlue = AuthColors.brandBlueDark;
  static const Color textSecondary = AuthColors.textSecondary;

  /// Soft top-to-bottom wash behind the register panel's feature cards.
  static const LinearGradient leftGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6F9FE), AuthColors.brandPanel],
  );

  /// Light Material theme for the app shell.
  ///
  /// The auth pages and every redesigned dashboard page paint on white, so the
  /// widgets that pull their colours from the ambient theme rather than from a
  /// call site — dropdown menus, snack bars, text selection handles — have to
  /// be light too. Under [AppTheme.darkTheme] a dropdown on the login form
  /// opens as a dark sheet on a white page.
  static ThemeData get materialTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AuthColors.brandBlue,
        brightness: Brightness.light,
        primary: AuthColors.brandBlue,
        error: AuthColors.danger,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.surface,
    );

    return base.copyWith(
      dividerColor: AppColors.divider,
      textTheme: base.textTheme.apply(
        bodyColor: AuthColors.textPrimary,
        displayColor: AuthColors.textPrimary,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: AuthColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(AppColors.surface),
        ),
      ),
    );
  }
}
