import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Construction des thèmes clair et sombre de KANU.
///
/// Le site utilise deux familles : une serif « display » (Playfair Display)
/// pour les titres et une sans-serif (Lato/Raleway) pour le corps. Faute de
/// pouvoir embarquer ces fichiers ici, on s'appuie sur des familles système
/// (`serif` / `sans-serif`) tout en conservant les tailles, interlignages et
/// espacements de lettres du design.
class AppTheme {
  const AppTheme._();

  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final Color background =
        isDark ? AppColors.black : AppColors.lightBackground;
    final Color surface = isDark ? AppColors.card : AppColors.lightCard;
    final Color surfaceAlt = isDark ? AppColors.surface : AppColors.lightSurface;
    final Color border = isDark ? AppColors.border : AppColors.lightBorder;
    final Color onSurface = isDark ? AppColors.white : AppColors.lightText;
    final Color muted = isDark ? AppColors.muted : AppColors.lightMuted;
    final Color primary = isDark ? AppColors.red : AppColors.lightPrimary;

    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: Colors.black,
      tertiary: AppColors.silver,
      onTertiary: Colors.black,
      error: AppColors.danger,
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceAlt,
      outline: border,
      outlineVariant: isDark ? AppColors.borderSoft : AppColors.lightBorder,
    );

    final TextTheme textTheme = _textTheme(onSurface, muted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      dividerColor: border,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          letterSpacing: 2.4,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.charcoal : AppColors.lightSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: muted.withValues(alpha: 0.7)),
        labelStyle: TextStyle(color: muted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: border),
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(
            letterSpacing: 1.6,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(letterSpacing: 0.6),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: onSurface, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.dark : AppColors.lightSurface,
        selectedItemColor: primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppColors.dark : AppColors.lightSurface,
        indicatorColor: primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, letterSpacing: 0.6, color: muted),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? primary : muted,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surface : AppColors.lightText,
        contentTextStyle: TextStyle(
          color: isDark ? AppColors.white : Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      listTileTheme: ListTileThemeData(
        iconColor: muted,
        textColor: onSurface,
      ),
    );
  }

  static TextTheme _textTheme(Color onSurface, Color muted) {
    const String display = 'serif';
    const String body = 'sans-serif';

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: display,
        fontSize: 44,
        height: 1.1,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      displayMedium: TextStyle(
        fontFamily: display,
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w300,
        color: onSurface,
      ),
      displaySmall: TextStyle(
        fontFamily: display,
        fontSize: 28,
        height: 1.2,
        fontWeight: FontWeight.w300,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: display,
        fontSize: 24,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      headlineSmall: TextStyle(
        fontFamily: display,
        fontSize: 21,
        fontWeight: FontWeight.w400,
        color: onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: display,
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: body,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontFamily: body,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: body,
        fontSize: 16,
        height: 1.5,
        color: onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: body,
        fontSize: 14,
        height: 1.5,
        color: onSurface,
      ),
      bodySmall: TextStyle(
        fontFamily: body,
        fontSize: 12.5,
        height: 1.45,
        color: muted,
      ),
      labelLarge: TextStyle(
        fontFamily: body,
        fontSize: 13,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: body,
        fontSize: 11,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w600,
        color: muted,
      ),
      labelSmall: TextStyle(
        fontFamily: body,
        fontSize: 10,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w600,
        color: muted,
      ),
    );
  }
}
