import 'package:flutter/material.dart';

abstract final class AppColors {
  static const forest = Color(0xFF087A50),
      mint = Color(0xFFEAF8F0),
      paper = Color(0xFFFFFFFF);
  static const ink = Color(0xFF17251E),
      muted = Color(0xFF66736B),
      line = Color(0xFFE5ECE7);
  static const orange = Color(0xFF8A532A),
      blue = Color(0xFF397B60),
      lavender = Color(0xFF5C876C);
  static const white = Color(0xFFFFFFFF),
      dark = Color(0xFF111A15),
      darkCard = Color(0xFF1A2820);
  static const darkText = Color(0xFFF2F7F3),
      darkMuted = Color(0xFFACBDB0),
      darkLine = Color(0xFF344D3E);
  static const bright = Color(0xFF20A66D),
      pale = Color(0xFFF5F8F6),
      lime = Color(0xFFBDE7CE);
}

ThemeData lumaTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.forest,
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFF75D6A5) : AppColors.forest,
        onPrimary: dark ? AppColors.dark : AppColors.white,
        primaryContainer: dark ? const Color(0xFF213C2D) : AppColors.mint,
        onPrimaryContainer: dark ? AppColors.darkText : AppColors.forest,
        surface: dark ? AppColors.darkCard : AppColors.white,
        surfaceContainerLowest: dark ? AppColors.dark : AppColors.white,
        surfaceContainerLow: dark ? const Color(0xFF16231B) : AppColors.pale,
        onSurface: dark ? AppColors.darkText : AppColors.ink,
        onSurfaceVariant: dark ? AppColors.darkMuted : AppColors.muted,
        outlineVariant: dark ? AppColors.darkLine : AppColors.line,
        outline: dark ? AppColors.darkMuted : const Color(0xFF879B8D),
        secondary: dark ? const Color(0xFFBAD8C5) : const Color(0xFF497A60),
        error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFB33535),
      );
  TextStyle text(
    double size,
    FontWeight weight, {
    double? height,
    double? tracking,
    Color? color,
  }) => TextStyle(
    fontFamily: 'Inter',
    fontSize: size,
    fontWeight: weight,
    height: height,
    letterSpacing: tracking,
    color: color ?? scheme.onSurface,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: dark ? AppColors.dark : AppColors.white,
    textTheme: TextTheme(
      displaySmall: text(34, FontWeight.w600, height: 1.15, tracking: -1.5),
      headlineMedium: text(26, FontWeight.w600, height: 1.2, tracking: -.8),
      titleLarge: text(22, FontWeight.w600, tracking: -.5),
      titleMedium: text(16, FontWeight.w600, tracking: -.25),
      titleSmall: text(14, FontWeight.w600),
      bodyLarge: text(15, FontWeight.w400, height: 1.45),
      bodyMedium: text(13, FontWeight.w400, height: 1.5),
      bodySmall: text(
        11,
        FontWeight.w400,
        height: 1.45,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: text(13, FontWeight.w600),
      labelMedium: text(12, FontWeight.w500),
      labelSmall: text(10, FontWeight.w600, tracking: .7),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? AppColors.dark : AppColors.white,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      toolbarHeight: 64,
      titleTextStyle: text(22, FontWeight.w600, tracking: -.7),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      labelStyle: text(13, FontWeight.w400, color: scheme.onSurfaceVariant),
      hintStyle: text(14, FontWeight.w400, color: scheme.onSurfaceVariant),
      helperMaxLines: 3,
      errorMaxLines: 3,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        textStyle: text(14, FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.outlineVariant),
        textStyle: text(13, FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: text(12, FontWeight.w600),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        iconSize: 21,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      selectedColor: scheme.primaryContainer,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: text(12, FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      showCheckmark: false,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      iconColor: scheme.primary,
      titleTextStyle: text(14, FontWeight.w500),
      subtitleTextStyle: text(
        12,
        FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
      minVerticalPadding: 12,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: scheme.surface,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(5),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        textStyle: WidgetStatePropertyAll(text(12, FontWeight.w500)),
      ),
    ),
  );
}

IconData categoryIcon(String cat) => switch (cat) {
  'food' => Icons.restaurant_rounded,
  'transport' => Icons.directions_car_filled_outlined,
  'shopping' => Icons.shopping_bag_outlined,
  'gift' => Icons.volunteer_activism_outlined,
  'gym' => Icons.fitness_center_rounded,
  'bills' => Icons.receipt_long_outlined,
  'health' => Icons.favorite_border_rounded,
  'education' => Icons.school_outlined,
  'subscription' => Icons.autorenew_rounded,
  'income' => Icons.south_west_rounded,
  'investment' => Icons.show_chart_rounded,
  'balance' => Icons.account_balance_wallet_outlined,
  'entertainment' => Icons.headphones_outlined,
  _ => Icons.category_outlined,
};
Color categoryColor(String cat) => switch (cat) {
  'food' => const Color(0xFF218B60),
  'transport' => const Color(0xFF426C55),
  'investment' => const Color(0xFF0B6845),
  'shopping' => const Color(0xFF5C8468),
  _ => AppColors.forest,
};
