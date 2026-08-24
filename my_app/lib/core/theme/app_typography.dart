import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextStyle get brandTitle => GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
  );

  static TextStyle get heading1 => GoogleFonts.plusJakartaSans(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static TextStyle get heading2 => GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static TextStyle get heading3 => GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  static TextStyle get body =>
      GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400);

  static TextStyle get bodyMedium =>
      GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500);

  static TextStyle get bodyBold =>
      GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600);

  static TextStyle get caption =>
      GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500);

  static TextStyle get overline => GoogleFonts.plusJakartaSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );
}
