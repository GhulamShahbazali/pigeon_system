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
    String? text,
    String? name,
    this.imageUrl,
    this.size = 40,
    this.gradient,
    this.hasBorder = false,
  }) : text = name ?? text ?? '?';

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;
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
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // While the photo loads (or if it fails), show the initial so the
              // circle is never blank.
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _initial(),
              errorBuilder: (context, _, __) => _initial(),
            )
          : _initial(),
    );
  }

  Widget _initial() => Center(
        child: Text(
          text.isNotEmpty ? text[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: size * 0.42,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}
