import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 带品牌渐变的模型头像（圆角方块 + 星标图标，颜色按模型名映射）
class ModelAvatar extends StatelessWidget {
  final String model;
  final double size;
  final IconData icon;
  const ModelAvatar({
    super.key,
    required this.model,
    this.size = 36,
    this.icon = Icons.auto_awesome,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ModelPalette.gradientFor(model);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: size * 0.52),
    );
  }
}
