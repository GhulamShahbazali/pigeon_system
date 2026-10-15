import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand tokens from docs/design-system/theme.md & pigeonfly-ui.css
  static const Color brand = Color(0xFF2F6BFF);
  static const Color brandDark = Color(0xFF1E49B8);
  static const Color brand600 = Color(0xFF2D62E6);
  static const Color brand50 = Color(0xFFEEF3FF);
  static const Color brand100 = Color(0xFFDCE6FF);

  // Amber / Gold tokens
  static const Color amber = Color(0xFFF5A524);
  static const Color amber50 = Color(0xFFFEF3E0);
  static const Color amberInk = Color(0xFF9A6208);

  // Ink & text
  static const Color ink = Color(0xFF0B1020);
  static const Color ink2 = Color(0xFF394153);
  static const Color sub = Color(0xFF6B7280);
  static const Color mut = Color(0xFFA4ABB8);
  static const Color muted = Color(0xFFA4ABB8);
  static const Color brandSoft = Color(0xFFEEF3FF);
  static const Color white70 = Color(0xB3FFFFFF);

  // Backgrounds, cards & lines
  static const Color line = Color(0xFFECEEF2);
  static const Color hair = Color(0xFFF3F4F7);
  static const Color soft = Color(0xFFF6F7F9);
  static const Color bg = Color(0xFFF4F5F8);
  static const Color card = Color(0xFFFFFFFF);

  // Status
  static const Color ok = Color(0xFF12B76A);
  static const Color ok50 = Color(0xFFE7F8F0);
  static const Color danger = Color(0xFFF04438);
  static const Color danger50 = Color(0xFFFEECEB);

  // Overlay & Alpha colors
  static const Color white14 = Color(0x24FFFFFF);
  static const Color white16 = Color(0x29FFFFFF);
  static const Color white28 = Color(0x47FFFFFF);
  static const Color white30 = Color(0x4DFFFFFF);
  static const Color white90 = Color(0xE6FFFFFF);

  static const Color shadowColor = Color(0x10101828); // rgba(16,24,40,.06)
  static const Color brandShadowColor = Color(0x472F6BFF); // rgba(47,107,255,.28)
  static const Color dangerShadowColor = Color(0x42F04438); // rgba(240,68,56,.26)

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4C86FF), Color(0xFF2F6BFF), Color(0xFF1E49B8)],
  );

  static const LinearGradient heroMeshSky = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4F8BFF), Color(0xFF143A86)],
  );

  static const LinearGradient duskMesh = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8A6CF0), Color(0xFF2A1D63)],
  );

  static const LinearGradient dawnMesh = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9E7A), Color(0xFFC2410C)],
  );

  static const LinearGradient avatarBlue = LinearGradient(
    colors: [Color(0xFF8FB4FF), Color(0xFF2F6BFF)],
  );

  static const LinearGradient avatarPurple = LinearGradient(
    colors: [Color(0xFFB79BFF), Color(0xFF6D4CE6)],
  );

  static const LinearGradient avatarGold = LinearGradient(
    colors: [Color(0xFFFFC48F), Color(0xFFF5A524)],
  );

  static const LinearGradient avatarGreen = LinearGradient(
    colors: [Color(0xFF7BE0C3), Color(0xFF12B76A)],
  );

  // Message chat & pill colors
  static const Color chatBg = Color(0xFFE9EEF3);
  static const Color tickRead = Color(0xFF2F6BFF);
  static const Color tickDelivered = Color(0xFFA4ABB8);
  static const Color greenExcel = Color(0xFF21A366);
  static const Color purpleImage = Color(0xFF6D4CE6);
  static const Color purpleBg = Color(0xFFF0E9FF);
  static const Color pinkVideo = Color(0xFFE23D6B);
  static const Color pinkBg = Color(0xFFFFE9EE);
  static const Color whatsApp = Color(0xFF25D366);
  static const Color whatsAppBusiness = Color(0xFF075E54);
  static const Color warnBg = Color(0xFFFFF6E6);
  static const Color warnBorder = Color(0xFFF6E2BE);
}
