import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';

class AppAvatar extends StatelessWidget {
  final String text;
  final String? imageUrl;
  final double size;
  final Gradient? gradient;
  final bool hasBorder;

  const AppAvatar({
    super.key,
    required this.text,
    this.imageUrl,
    this.size = 40,
    this.gradient,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient ?? AppColors.avatarBlue,
        border: hasBorder
            ? Border.all(color: Colors.white, width: 2.5)
            : null,
        boxShadow: AppShadows.xs,
      ),
      child: Center(
        child: Text(
          text.isNotEmpty ? text[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
