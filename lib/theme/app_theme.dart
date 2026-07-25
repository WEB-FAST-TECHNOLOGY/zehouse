import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static bool isDark = false;

  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.light,
  );

  // Brand Colors - Cyber Neon and Deep Space Slate
  static Color get primary =>
      isDark ? const Color(0xFF00F2FE) : const Color(0xFF0F172A);
  static Color get primaryLight =>
      isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E293B);
  static Color get primaryMuted =>
      isDark ? const Color(0x3300F2FE) : const Color(0x1F0F172A);
  static Color get accent =>
      isDark ? const Color(0xFF7C3AED) : const Color(0xFFD97706);
  static Color get accentLight =>
      isDark ? const Color(0x1A7C3AED) : const Color(0xFFFEF3C7);

  // Semantic Colors - Emerald, Gold, Rose
  static Color get success =>
      isDark ? const Color(0xFF10B981) : const Color(0xFF16A34A);
  static Color get successLight =>
      isDark ? const Color(0x1A10B981) : const Color(0xFFDCFCE7);
  static Color get warning =>
      isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706);
  static Color get warningLight =>
      isDark ? const Color(0x1AF59E0B) : const Color(0xFFFEF3C7);
  static Color get error =>
      isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);
  static Color get errorLight =>
      isDark ? const Color(0x1AEF4444) : const Color(0xFFFEE2E2);
  static Color get info =>
      isDark ? const Color(0xFFA855F7) : const Color(0xFF7C3AED);
  static Color get infoLight =>
      isDark ? const Color(0x1AA855F7) : const Color(0xFFF3F0FF);

  // Surface Colors - Glowing Dark and Soft Light
  static Color get surface =>
      isDark ? const Color(0xFF131B2E) : const Color(0xFFFFFFFF);
  static Color get surfaceVariant =>
      isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
  static Color get background =>
      isDark ? const Color(0xFF0B0E14) : const Color(0xFFF8FAFC);
  static Color get border =>
      isDark ? const Color(0xFF262F40) : const Color(0xFFE2E8F0);
  static Color get muted =>
      isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
  static Color get textPrimary =>
      isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
  static Color get textSecondary =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

  // Property Type Colors
  static Color get forSale =>
      isDark ? const Color(0xFF00F2FE) : const Color(0xFF0F172A);
  static Color get forRent =>
      isDark ? const Color(0xFFA855F7) : const Color(0xFF7C3AED);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFF1F5F9),
        onPrimaryContainer: primary,
        secondary: accent,
        onSecondary: Colors.white,
        secondaryContainer: accentLight,
        onSecondaryContainer: accent,
        tertiary: info,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceVariant,
        outline: border,
        outlineVariant: Color(0xFFF1F5F9),
        error: error,
        onError: Colors.white,
        errorContainer: errorLight,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: _buildAppBarTheme(base.colorScheme),
      cardTheme: _buildCardTheme(),
      inputDecorationTheme: _buildInputTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      chipTheme: _buildChipTheme(),
      navigationBarTheme: _buildNavigationBarTheme(base.colorScheme),
      bottomSheetTheme: _buildBottomSheetTheme(),
      dividerTheme: _buildDividerTheme(),
      snackBarTheme: _buildSnackBarTheme(),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primary,
        onPrimary: Colors
            .black, // Dark primary is light-colored (cyan) so onPrimary should be black
        primaryContainer: Color(0xFF1E293B),
        onPrimaryContainer: primary,
        secondary: accent,
        onSecondary: Colors.white,
        secondaryContainer: accentLight,
        onSecondaryContainer: accent,
        tertiary: info,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceVariant,
        outline: border,
        outlineVariant: Color(0xFF1E293B),
        error: error,
        onError: Colors.white,
        errorContainer: errorLight,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: _buildTextTheme(base.textTheme),
      appBarTheme: _buildAppBarTheme(base.colorScheme),
      cardTheme: _buildCardTheme(),
      inputDecorationTheme: _buildInputTheme(),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      outlinedButtonTheme: _buildOutlinedButtonTheme(),
      chipTheme: _buildChipTheme(),
      navigationBarTheme: _buildNavigationBarTheme(base.colorScheme),
      bottomSheetTheme: _buildBottomSheetTheme(),
      dividerTheme: _buildDividerTheme(),
      snackBarTheme: _buildSnackBarTheme(),
    );
  }

  // Futuristic Typography System: Space Grotesk (Headers) + Outfit (Body)
  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.outfitTextTheme(base).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      labelLarge: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.3,
      ),
      labelSmall: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: muted,
        letterSpacing: 0.3,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(ColorScheme scheme) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    );
  }

  static CardThemeData _buildCardTheme() {
    return CardThemeData(
      elevation: 0,
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: border),
      ),
    );
  }

  // Modern Rounded Outlined Input Fields with subtle glow fill
  static InputDecorationTheme _buildInputTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0x0F00F2FE) : const Color(0x080F172A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: error, width: 2),
      ),
      labelStyle: GoogleFonts.outfit(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      hintStyle: GoogleFonts.outfit(fontSize: 15, color: muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: border),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ChipThemeData _buildChipTheme() {
    return ChipThemeData(
      backgroundColor: surfaceVariant,
      selectedColor: primary,
      labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      side: const BorderSide(color: Colors.transparent),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  static NavigationBarThemeData _buildNavigationBarTheme(ColorScheme scheme) {
    return NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      height: 64,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: primary,
          );
        }
        return GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: primary, size: 24);
        }
        return IconThemeData(color: muted, size: 24);
      }),
    );
  }

  static BottomSheetThemeData _buildBottomSheetTheme() {
    return BottomSheetThemeData(
      backgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  static DividerThemeData _buildDividerTheme() {
    return DividerThemeData(color: border, thickness: 1, space: 0);
  }

  static SnackBarThemeData _buildSnackBarTheme() {
    return SnackBarThemeData(
      backgroundColor: textPrimary,
      contentTextStyle: GoogleFonts.outfit(fontSize: 14, color: surface),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    );
  }
}
