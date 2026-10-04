import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  // Headings & Display (Plus Jakarta Sans per theme.md)
  static TextStyle get heroTitle => GoogleFonts.plusJakartaSans(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.1,
        color: Colors.white,
      );

  static TextStyle get splashTitle => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: Colors.white,
      );

  static TextStyle get screenTitle => GoogleFonts.plusJakartaSans(
        fontSize: 23,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: AppColors.ink,
      );

  static TextStyle get sectionTitle => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: AppColors.ink,
      );

  static TextStyle get cardTitle => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: AppColors.ink,
      );

  // Body & Labels (Inter per theme.md)
  static TextStyle get subtitleWhite => GoogleFonts.inter(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        color: AppColors.white90,
        height: 1.4,
      );

  static TextStyle get bodyBold => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: AppColors.ink,
      );

  static TextStyle get bodyRegular => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.ink2,
      );

  static TextStyle get subText => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.sub,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.mut,
      );

  static TextStyle get overline => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
        color: AppColors.sub,
      );

  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      );

  // Numbers & Averages (Plus Jakarta Sans)
  static TextStyle get statNumber => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: AppColors.brand,
      );

  static TextStyle get totalBigNumber => GoogleFonts.plusJakartaSans(
        fontSize: 25,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: Colors.white,
      );

  // Wireframe aliases
  static TextStyle get h2 => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: AppColors.ink,
      );

  static TextStyle get h3 => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: AppColors.ink,
      );

  static TextStyle get h4 => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
        color: AppColors.ink,
      );

  static TextStyle get body => GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
        height: 1.4,
      );

  static TextStyle get captionBold => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      );

  static TextStyle get labelUppercase => GoogleFonts.inter(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: AppColors.sub,
      );
}
