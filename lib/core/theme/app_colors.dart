import 'package:flutter/material.dart';

/// App color palette matching the Figma design system.
class AppColors {
  // Prevent creating instances of this class.
  AppColors._();

  // Primary brand colors
  static const Color sherwoodGreen = Color(0xFF03312E); // Main dark green
  static const Color ginFizz = Color(
    0xFFFFFAE3,
  ); // Warm cream for text/backgrounds
  static const Color leafGreen = Color(
    0xFF4B8A37,
  ); // Accent green for logo and indicators
  static const Color sunglo = Color(0xFFDF7373); // Coral accent color

  // Supporting neutral and soft tones
  static const Color edward = Color(0xFF9AADAB); // Muted slate gray
  static const Color vanillaIce = Color(0xFFF8E5E5); // Light pastel pink
  static const Color athsSpecial = Color(0xFFF0EBD5); // Warm cream card fill
  static const Color opal = Color(0xFFA3C4BC); // Soft sage green
  static const Color goldSand = Color(0xFFE2C08D); // Soft gold
  static const Color pewter = Color(0xFF98AA9E); // Muted green gray

  // Standard utility colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Common transparent shades used in Figma
  static const Color ginFizz4 = Color(
    0x0AFFFCE3,
  ); // ~4% opacity for ring strokes
  static const Color sunglo15 = Color(0x26DF7373); // 15% opacity for logo ring
  static const Color sunglo40 = Color(
    0x66DF7373,
  ); // 40% opacity for inactive coral dots
  static const Color leafGreen40 = Color(
    0x664B8A37,
  ); // ~40% opacity for inactive green dots
}
