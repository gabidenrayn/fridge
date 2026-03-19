import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get heading1 => GoogleFonts.exo2(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle get heading2 => GoogleFonts.exo2(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading3 => GoogleFonts.exo2(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get body => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySecondary => GoogleFonts.nunito(
        fontSize: 13,
        color: AppColors.textSecondary,
      );

  static TextStyle get caption => GoogleFonts.nunito(
        fontSize: 11,
        color: AppColors.textMuted,
      );

  static TextStyle get label => GoogleFonts.exo2(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
        letterSpacing: 1.2,
      );

  static TextStyle get badge => GoogleFonts.exo2(
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      );
}
