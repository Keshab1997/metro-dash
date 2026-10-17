import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/assets.dart';
import '../core/config.dart';
import '../core/palette.dart';
import '../game/projection.dart';

class _Prop {
  _Prop(
      {required this.side,
      required this.z,
      required this.sprite,
      required this.height});

  final double side; // -1 left, +1 right
  final double z;
  final String sprite;
  final double height;
}

class _Building {
  _Building({
    required this.height,
    required this.z,
    required this.sprite,
    required this.lit,
  });

  final double height; // world units, base to roof
  final double z;
  final String sprite;
  final bool lit;
  double aspect = 0.8; // replaced by the decoded sprite's own aspect
}

/// The street beside the corridor: AI-generated house sprites on both sides,
/// and the lamp poles with their sagging string lights between them.
/// Owner: worker A (Batch 1).
class Environment {
  Environment({int seed = 7}) : _rnd = math.Random(seed);

  final math.Random _rnd;
  final List<_Building> _left = <_Building>[];
  final List<_Building> _right = <_Building>[];
  final List<_Prop> _props = <_Prop>[];
  double _frontier = 6;

  /// House sprites are drawn from their base centre. The wall line sits just
  /// outside the parapet: any further out and a house leaves the camera
  /// frustum whenever it is near, which empties the street exactly when the
  /// player is looking at it.
  static const double _wallLine = 2.15;

  void reset() {
    _left.clear();
    _right.clear();
    _props.clear();
    _frontier = 6;
  }

  void update(double runnerZ, {GameAssets? assets}) {
    final reach = runnerZ + Tune.spawnAhead + 8;
    while (_frontier < reach) {
      _spawnRow(_frontier, assets);
      _frontier += 5.4 + _rnd.nextDouble() * 2.6;
    }
    final cut = runnerZ - Tune.recycleBehind;
    _left.removeWhere((b) => b.z + 8 < cut);
    _right.removeWhere((b) => b.z + 8 < cut);
    _props.removeWhere((f) => f.z + 6 < cut);
  }

  void _spawnRow(double z, GameAssets? assets) {
    // tall city blocks with a couple of low shops between them
    const list = <double>[7.6, 5.4, 6.8, 3.6, 8.4, 4.8];
    for (final side in const <int>[-1, 1]) {
      final sprite =
          GameAssets.houseKeys[_rnd.nextInt(GameAssets.houseKeys.length)];
      final b = _Building(
        height: list[_rnd.nextInt(list.length)],
        z: z + _rnd.nextDouble() * 0.6,
        sprite: sprite,
        lit: _rnd.nextInt(100) < 45,
      );
      final image = assets?.sprite(sprite);
      if (image != null && image.height > 0) {
        b.aspect = image.width / image.height;
      }
      (side < 0 ? _left : _right).add(b);
    }
    // a tea cart or a stall now and then, tucked against the parapet
    if (assets != null && _rnd.nextInt(100) < 55) {
      final sprite =
          GameAssets.propKeys[_rnd.nextInt(GameAssets.propKeys.length)];
      _props.add(
        _Prop(
          side: _rnd.nextBool() ? -1 : 1,
          z: z + 1.2 + _rnd.nextDouble() * 1.6,
          sprite: sprite,
          height: sprite == 'prop_cart' ? 1.05 : 1.35,
        ),
      );
    }
  }

  void paint(Canvas canvas, Projection p, double time, GameAssets? assets) {
    final visible = <_Building>[..._left, ..._right]
        .where((b) => b.z - p.camZ > -3 && b.z - p.camZ < 48)
        .toList()
      ..sort((a, b) => b.z.compareTo(a.z)); // far first
    for (final b in visible) {
      final side = _left.contains(b) ? -1.0 : 1.0;
      _paintBuilding(canvas, p, b, side, assets);
    }
    _paintProps(canvas, p, assets);
    _paintLights(canvas, p, time);
  }

  void _paintBuilding(
    Canvas canvas,
    Projection p,
    _Building b,
    double side,
    GameAssets? assets,
  ) {
    final fade = p.fadeAt(b.z - 10);
    if (fade <= 0.02) return;

    final aspect = b.aspect <= 0 ? 0.8 : b.aspect;
    final width = b.height * aspect;
    final centreX = side * (_wallLine + width / 2);
    final base = p.project(centreX, 0, b.z);
    final h = b.height * base.scale;
    final w = width * base.scale;
    final rect = Rect.fromLTWH(
      base.screen.dx - w / 2,
      base.screen.dy - h,
      w,
      h,
    );

    final image = assets?.sprite(b.sprite);
    if (image != null) {
      final paint = Paint();
      if (fade < 0.99) {
        paint.color = Color.fromARGB((255 * fade).round(), 255, 255, 255);
      }
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        paint,
      );
    } else {
      // canvas stand-in, so a missing sprite still leaves a street behind
      canvas.drawRect(
          rect, Paint()..color = Pal.wallCream.withValues(alpha: fade));
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, h * 0.08),
        Paint()..color = Pal.roofRust.withValues(alpha: fade),
      );
    }

    // a lit window is the cheapest way to make a house read as "alive"
    if (b.lit && (b.z - p.camZ) < 30) {
      canvas.drawRect(
        Rect.fromLTWH(
          rect.left + rect.width * 0.18,
          rect.top + rect.height * 0.30,
          rect.width * 0.22,
          rect.height * 0.14,
        ),
        Paint()..color = Pal.coin.withValues(alpha: 0.55 * fade),
      );
    }
  }

  /// Street-scale props (tea cart, stall) sitting just outside the parapet.
  void _paintProps(Canvas canvas, Projection p, GameAssets? assets) {
    if (assets == null) return;
    final visible = _props
        .where((f) => f.z - p.camZ > -2 && f.z - p.camZ < 40)
        .toList()
      ..sort((a, b) => b.z.compareTo(a.z));
    for (final f in visible) {
      final image = assets.sprite(f.sprite);
      if (image == null) continue;
      final fade = p.fadeAt(f.z - 12);
      if (fade <= 0.03) continue;
      final x = f.side * 2.55;
      final base = p.project(x, 0, f.z);
      final h = f.height * base.scale;
      final w = h * image.width / image.height;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(base.screen.dx - w / 2, base.screen.dy - h, w, h),
        fade >= 0.99
            ? Paint()
            : (Paint()
              ..color = Color.fromARGB((255 * fade).round(), 255, 255, 255)),
      );
    }
  }

  void _paintLights(Canvas canvas, Projection p, double time) {
    const poleX = Tune.trackHalf + 0.55;
    const spacing = 7.0;
    final start = ((p.camZ + 1) / spacing).ceil() * spacing;
    for (double z = start; z < p.camZ + 30; z += spacing) {
      for (final side in const <double>[-1, 1]) {
        final x = side * poleX;
        final base = p.project(x, 0, z);
        final top = p.project(x, 3.7, z);
        final fade = p.fadeAt(z);
        canvas.drawLine(
          base.screen,
          top.screen,
          Paint()
            ..color = Pal.railDark.withValues(alpha: fade)
            ..strokeWidth = math.max(1.0, 0.055 * base.scale),
        );
        // the wire to the next pole, sagging
        if (z + spacing < p.camZ + 30) {
          final nextTop = p.project(x, 3.7, z + spacing);
          final mid = p.project(x, 3.25, z + spacing / 2);
          canvas.drawPath(
            Path()
              ..moveTo(top.screen.dx, top.screen.dy)
              ..quadraticBezierTo(
                mid.screen.dx,
                mid.screen.dy,
                nextTop.screen.dx,
                nextTop.screen.dy,
              ),
            Paint()
              ..color = Pal.ink.withValues(alpha: 0.45 * fade)
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(0.8, 0.028 * base.scale),
          );
          // bulbs
          for (final t in const <double>[0.25, 0.5, 0.75]) {
            final u = 2 * (1 - t) * t;
            final bx = top.screen.dx * (1 - t) * (1 - t) +
                mid.screen.dx * u +
                nextTop.screen.dx * t * t;
            final by = top.screen.dy * (1 - t) * (1 - t) +
                mid.screen.dy * u +
                nextTop.screen.dy * t * t;
            final glow = 0.6 + 0.4 * math.sin(time * 3 + z + t * 4);
            canvas.drawCircle(
              Offset(bx, by + 0.06 * base.scale),
              math.max(1.0, 0.045 * base.scale * glow),
              Paint()..color = Pal.coin.withValues(alpha: 0.85 * fade),
            );
          }
        }
      }
    }
  }
}
