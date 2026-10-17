import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// Decoded sprites, loaded once at boot.
///
/// Every image here is AI-generated inside the repository pipeline
/// (docs/ASSET_PIPELINE.md) and committed under `assets/sprites/` — no
/// third-party art, no network at runtime. Lookups go through [sprite], which
/// returns null instead of throwing: a missing or corrupt file makes the
/// renderer fall back to canvas shapes, never a black screen.
class GameAssets {
  GameAssets._(this._sprites);

  final Map<String, ui.Image> _sprites;

  static const skylineKey = 'skyline';
  static const ballastKey = 'ballast';
  static const grassKey = 'grass';
  static const concreteKey = 'concrete';
  static const sleeperKey = 'sleeper';
  static const railHeadKey = 'rail_head';
  static const dustKey = 'dust';
  static const rollKey = 'roll';
  static const coinKey = 'coin';

  /// Runner animation frames, in order.
  final List<String> runFrameKeys = <String>[
    'runner_run_0',
    'runner_run_1',
  ];

  /// One image per file: key -> path.
  static const Map<String, String> files = <String, String>{
    skylineKey: 'assets/sprites/bg_skyline.jpg',
    ballastKey: 'assets/sprites/texture_ballast.jpg',
    grassKey: 'assets/sprites/texture_grass.jpg',
    concreteKey: 'assets/sprites/texture_concrete.jpg',
    sleeperKey: 'assets/sprites/texture_sleeper.jpg',
    railHeadKey: 'assets/sprites/texture_rail_head.jpg',
    'prop_signal': 'assets/sprites/prop_signal.png',
    'prop_catenary': 'assets/sprites/prop_catenary.png',
    'prop_marker': 'assets/sprites/prop_marker.png',
    'runner_run_0': 'assets/sprites/runner_run_0.png',
    'runner_run_1': 'assets/sprites/runner_run_1.png',
    'runner_air': 'assets/sprites/runner_air.png',
    'runner_run_2': 'assets/sprites/runner_run_2.png',
    'runner_run_3': 'assets/sprites/runner_run_3.png',
    'runner_roll': 'assets/sprites/runner_roll.png',
    'dust': 'assets/sprites/dust.png',
    'barrier_low': 'assets/sprites/barrier_low.png',
    'barrier_high': 'assets/sprites/barrier_high.png',
    'train': 'assets/sprites/train.png',
    'cones': 'assets/sprites/cones.png',
    coinKey: 'assets/sprites/coin.png',
    'house_0': 'assets/sprites/house_0.png',
    'house_1': 'assets/sprites/house_1.png',
    'house_2': 'assets/sprites/house_2.png',
  };

  ui.Image? sprite(String key) => _sprites[key];

  ui.Image get skyline => _sprites[skylineKey]!;
  ui.Image get airFrame => _sprites['runner_air']!;

  /// The tucked roll pose; the painter falls back to the air frame when the
  /// dedicated roll sprite is missing.
  ui.Image? get rollFrame => _sprites['runner_roll'];

  ui.Image? get dust => _sprites['dust'];
  List<ui.Image> get runFrames =>
      runFrameKeys.map((k) => _sprites[k]).whereType<ui.Image>().toList();

  /// The house sprites, in a stable order — the environment picks from these.
  static const List<String> houseKeys = <String>[
    'house_0',
    'house_1',
    'house_2'
  ];

  static Future<ui.Image?> _decode(AssetBundle bundle, String path) async {
    try {
      final data = await bundle.load(path);
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null; // missing sprite: the renderer has a fallback for everything
    }
  }

  static Future<GameAssets?> load({AssetBundle? bundle}) async {
    final b = bundle ?? rootBundle;
    final decoded = <String, ui.Image>{};
    for (final entry in files.entries) {
      final image = await _decode(b, entry.value);
      if (image != null) decoded[entry.key] = image;
    }
    if (decoded.isEmpty) return null;
    return GameAssets._(decoded);
  }
}
