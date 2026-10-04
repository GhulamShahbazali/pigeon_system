import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'pigeon_watermark.dart';

class PigeonLogo extends StatelessWidget {
  final double size;
  final Color? color;
  final bool hasBackground;

  const PigeonLogo({
    super.key,
    this.size = 36,
    this.color,
    this.hasBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = PigeonWatermark(
      width: size * 0.58,
      height: size * 0.58,
      color: color ?? Colors.white,
    );

    if (!hasBackground) return iconWidget;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: iconWidget),
    );
  }
}
