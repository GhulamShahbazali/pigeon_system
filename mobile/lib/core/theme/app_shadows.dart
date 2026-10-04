import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppShadows {
  // Small shadow (cards & inputs)
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: AppColors.shadowColor,
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  // Extra small shadow
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: AppColors.shadowColor,
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
  ];

  // Primary brand button glow
  static const List<BoxShadow> brandButton = [
    BoxShadow(
      color: AppColors.brandShadowColor,
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  // Danger button shadow
  static const List<BoxShadow> dangerButton = [
    BoxShadow(
      color: AppColors.dangerShadowColor,
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  // Large floating card shadow
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x2405070F), // rgba(5,7,15,.14)
      blurRadius: 30,
      offset: Offset(0, 14),
    ),
  ];
}
