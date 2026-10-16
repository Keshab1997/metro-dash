import 'package:flutter/material.dart';

/// Locked art-direction palette (docs/ART_DIRECTION.md §3).
/// Nothing outside these tokens should appear in the game.
abstract final class Pal {
  static const skyTop = Color(0xFF7EC8E3);
  static const horizonWarm = Color(0xFFFFD9A0);
  static const sunGlow = Color(0xFFFF9E7A);

  static const railSteel = Color(0xFF9AA3A8);
  static const railDark = Color(0xFF6F787D);
  static const railShine = Color(0xFFD9E2E6);

  static const ballast = Color(0xFF8E7F6E);
  static const ballastDark = Color(0xFF6E6155);
  static const concrete = Color(0xFFC9C4BC);
  static const concreteDark = Color(0xFFA79F95);

  static const grass = Color(0xFF7FA65B);
  static const grassDeep = Color(0xFF5E8244);

  static const hoodie = Color(0xFF1F9E8F);
  static const accent = Color(0xFFFF8A3D);
  static const coin = Color(0xFFFFC63D);
  static const coinDeep = Color(0xFFE08A18);

  static const danger = Color(0xFFE5484D);
  static const ink = Color(0xFF2A2320);
  static const paper = Color(0xFFFFF6E6);

  static const wallCream = Color(0xFFF3DFB8);
  static const wallTeal = Color(0xFF9CCFC6);
  static const roofRust = Color(0xFFC56757);
  static const roofBlue = Color(0xFF5D7894);
  static const haze = Color(0xFFFFE9C9);
}
