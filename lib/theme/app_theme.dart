import 'package:flutter/material.dart';

/// 须弥AI v2 品牌配色（消费级轻松风格，延续月光紫）
class AppColors {
  // 品牌主色：须弥紫（呼应须弥Media的月光紫，延续家族视觉）
  static const Color primary = Color(0xFF7C5CFF);
  static const Color primaryDark = Color(0xFF5C3DFF);
  static const Color accent = Color(0xFF00D4B3);
  static const Color bgLight = Color(0xFFF7F6FF);
  static const Color bgDark = Color(0xFF101018);

  static const Color brandGradientStart = Color(0xFF9B7BFF);
  static const Color brandGradientEnd = Color(0xFF5C3DFF);

  /// 模型卡片渐变池：让不同模型有各自的辨识色（按关键字映射 + 哈希兜底）
  static const List<List<Color>> modelGradients = [
    [Color(0xFF6C8CFF), Color(0xFF4A62E8)], // 蓝（GPT/OpenAI）
    [Color(0xFF00C2A8), Color(0xFF00A6C2)], // 青（Gemini/GLM）
    [Color(0xFFFF9A5C), Color(0xFFFF6B4A)], // 橙（Claude/Mistral）
    [Color(0xFFB06CFF), Color(0xFF7C3DFF)], // 紫（Qwen/通义）
    [Color(0xFFFF5C8A), Color(0xFFE8447D)], // 粉（DeepSeek）
    [Color(0xFF34C6FF), Color(0xFF2E8BFF)], // 天蓝
    [Color(0xFFFFC93C), Color(0xFFFF9F1C)], // 金
    [Color(0xFF3DDC97), Color(0xFF21B573)], // 绿
  ];
}

/// 根据模型名挑选稳定的渐变配色
class ModelPalette {
  static List<Color> gradientFor(String model) {
    final m = model.toLowerCase();
    int idx;
    if (m.contains('gpt') || m.contains('openai')) {
      idx = 0;
    } else if (m.contains('gemini') || m.contains('glm') || m.contains('zhipu')) {
      idx = 1;
    } else if (m.contains('claude') || m.contains('mistral')) {
      idx = 2;
    } else if (m.contains('qwen') || m.contains('dashscope') || m.contains('tongyi')) {
      idx = 3;
    } else if (m.contains('deepseek')) {
      idx = 4;
    } else if (m.contains('grok')) {
      idx = 2;
    } else if (m.contains('llama') || m.contains('kimi') || m.contains('moonshot')) {
      idx = 6;
    } else {
      idx = m.codeUnits.fold<int>(0, (a, b) => a + b) %
          AppColors.modelGradients.length;
    }
    return AppColors.modelGradients[idx];
  }
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
          fontWeight: FontWeight.w700,
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
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? scheme.surfaceContainer : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: false,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
