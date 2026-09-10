import 'package:flutter/material.dart';

abstract final class AppColors {
  static const forest = Color(0xFF4056A1),
      mint = Color(0xFFE6EAF8),
      paper = Color(0xFFF7F5F0);
  static const ink = Color(0xFF242938),
      muted = Color(0xFF616471),
      line = Color(0xFFDCDDDC);
  static const orange = Color(0xFFAD5238),
      blue = Color(0xFF4056A1),
      lavender = Color(0xFF75679D);
  static const white = Color(0xFFFFFEFB),
      dark = Color(0xFF191C26),
      darkCard = Color(0xFF222634);
  static const darkText = Color(0xFFF1F0EA),
      darkMuted = Color(0xFFB8BDCB),
      darkLine = Color(0xFF424858);
  static const bright = Color(0xFFAAC0FF),
      pale = Color(0xFFF0EFEA),
      lime = Color(0xFFC9D1EC);
}

ThemeData lumaTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.forest,
        brightness: brightness,
      ).copyWith(
        primary: dark ? const Color(0xFFB5C5FF) : AppColors.forest,
        onPrimary: dark ? AppColors.dark : AppColors.white,
        primaryContainer: dark ? const Color(0xFF303C67) : AppColors.mint,
        onPrimaryContainer: dark ? AppColors.darkText : AppColors.forest,
        surface: dark ? AppColors.darkCard : AppColors.white,
        surfaceContainerLowest: dark ? AppColors.dark : AppColors.paper,
        surfaceContainerLow: dark ? const Color(0xFF282D3B) : AppColors.pale,
        onSurface: dark ? AppColors.darkText : AppColors.ink,
        onSurfaceVariant: dark ? AppColors.darkMuted : AppColors.muted,
        outlineVariant: dark ? AppColors.darkLine : AppColors.line,
        outline: dark ? AppColors.darkMuted : const Color(0xFF7B7F8C),
        secondary: dark ? const Color(0xFFFFB59E) : const Color(0xFFAD5238),
        tertiary: dark ? const Color(0xFF8BD5BB) : const Color(0xFF276955),
        onSecondary: dark ? AppColors.dark : AppColors.white,
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
    scaffoldBackgroundColor: dark ? AppColors.dark : AppColors.paper,
    textTheme: TextTheme(
      displaySmall: text(34, FontWeight.w600, height: 1.15, tracking: -1.0),
      headlineMedium: text(26, FontWeight.w600, height: 1.2, tracking: -.8),
      titleLarge: text(22, FontWeight.w600, tracking: -.5),
      titleMedium: text(16, FontWeight.w600, tracking: -.25),
      titleSmall: text(14, FontWeight.w600),
      bodyLarge: text(16, FontWeight.w400, height: 1.45),
      bodyMedium: text(14, FontWeight.w400, height: 1.5),
      bodySmall: text(
        12,
        FontWeight.w400,
        height: 1.45,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: text(13, FontWeight.w600),
      labelMedium: text(12, FontWeight.w500),
      labelSmall: text(10, FontWeight.w600, tracking: .7),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? AppColors.dark : AppColors.paper,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      toolbarHeight: 64,
      titleTextStyle: text(22, FontWeight.w600, tracking: -.7),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primaryContainer,
      elevation: 0,
      labelTextStyle: WidgetStatePropertyAll(text(12, FontWeight.w500)),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primaryContainer,
      selectedIconTheme: IconThemeData(color: scheme.primary),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
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
  'food' => const Color(0xFFAD5238),
  'transport' => const Color(0xFF4056A1),
  'investment' => const Color(0xFF75679D),
  'shopping' => const Color(0xFF276955),
  _ => AppColors.forest,
};
