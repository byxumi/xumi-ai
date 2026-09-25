import 'package:flutter/material.dart';

/// 须弥AI 品牌配色
class AppColors {
  // 品牌主色：须弥紫（呼应须弥Media的月光紫，延续家族视觉）
  static const Color primary = Color(0xFF7C5CFF);
  static const Color primaryDark = Color(0xFF5C3DFF);
  static const Color accent = Color(0xFF00D4B3);
  static const Color bgLight = Color(0xFFF7F6FC);
  static const Color bgDark = Color(0xFF101016);

  static const Color brandGradientStart = Color(0xFF8B6FFF);
  static const Color brandGradientEnd = Color(0xFF5C3DFF);
}

/// 全局主题配置
class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
    );
    return _compose(base, Brightness.light);
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
    );
    return _compose(base, Brightness.dark);
  }

  static ThemeData _compose(ThemeData base, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = base.colorScheme;

    return base.copyWith(
      scaffoldBackgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
            : Colors.white,
        hintStyle: TextStyle(color: scheme.outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark
            ? scheme.surfaceContainer
            : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        thickness: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark
            ? AppColors.bgDark.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        indicatorColor: scheme.primaryContainer,
        height: 68,
      ),
    );
  }
}