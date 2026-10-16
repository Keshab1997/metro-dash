import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Decoded sprites. Loaded once at boot; every painter call reuses the images.
///
/// Everything here is AI-generated inside the repo pipeline
/// (docs/ASSET_PIPELINE.md) — no third-party art, no network at runtime.
class GameAssets {
  GameAssets._(this.skyline, this.runFrames, this.airFrame);

  final ui.Image skyline;
  final List<ui.Image> runFrames;
  final ui.Image airFrame;

  static const skylinePath = 'assets/sprites/bg_skyline.jpg';
  static const runPaths = <String>[
    'assets/sprites/runner_run_0.png',
    'assets/sprites/runner_run_1.png',
  ];
  static const airPath = 'assets/sprites/runner_air.png';

  static Future<ui.Image> _decode(AssetBundle bundle, String path) async {
    final data = await bundle.load(path);
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Returns null when a sprite is missing — the renderer then falls back to
  /// canvas-drawn stand-ins, so a bad asset can never black-screen the game.
  static Future<GameAssets?> load({AssetBundle? bundle}) async {
    final b = bundle ?? rootBundle;
    try {
      final skyline = await _decode(b, skylinePath);
      final run = <ui.Image>[];
      for (final p in runPaths) {
        run.add(await _decode(b, p));
      }
      final air = await _decode(b, airPath);
      return GameAssets._(skyline, run, air);
    } catch (_) {
      return null;
    }
  }
}
