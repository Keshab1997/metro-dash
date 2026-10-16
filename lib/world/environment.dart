import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/palette.dart';
import '../game/projection.dart';

class _Building {
  _Building({
    required this.x,
    required this.w,
    required this.h,
    required this.z,
    required this.wall,
    required this.roof,
    required this.lit,
    required this.tank,
  });

  final double x; // inner edge, closest to the track (signed)
  final double w; // depth away from the track
  final double h;
  final double z;
  final Color wall;
  final Color roof;
  final bool lit;
  final bool tank;
}

/// Every non-track thing beside the corridor: the row of houses, the lamp
/// poles and their sagging string lights. Owner: worker A (Batch 1).
///
/// The camera looks at the corridor from behind, so the surface it actually
/// sees of a building is its **side wall** (the plane at constant x) — the
/// windows and the festival pennants live on that plane, not on the facade
/// facing the track.
class Environment {
  Environment({int seed = 7}) : _rnd = math.Random(seed);

  final math.Random _rnd;
  final List<_Building> _left = <_Building>[];
  final List<_Building> _right = <_Building>[];
  double _frontier = 6;

  static const double _depth = 3.4;

  static const List<Color> _walls = <Color>[
    Pal.wallCream,
    Pal.wallTeal,
    Pal.paper,
    Pal.concrete,
  ];
  static const List<Color> _roofs = <Color>[
    Pal.roofRust,
    Pal.roofBlue,
    Pal.ballastDark
  ];

  void reset() {
    _left.clear();
    _right.clear();
    _frontier = 6;
  }

  void update(double runnerZ) {
    final reach = runnerZ + Tune.spawnAhead + 6;
    while (_frontier < reach) {
      _spawnRow(_frontier);
      _frontier += 6.2 + _rnd.nextDouble() * 2.8;
    }
    final cut = runnerZ - Tune.recycleBehind;
    _left.removeWhere((b) => b.z + 8 < cut);
    _right.removeWhere((b) => b.z + 8 < cut);
  }

  void _spawnRow(double z) {
    for (final side in const <int>[-1, 1]) {
      final gap = 3.05 + _rnd.nextDouble() * 0.7;
      final h = 3.4 + _rnd.nextDouble() * 3.8;
      final w = 2.8 + _rnd.nextDouble() * 2.0;
      final b = _Building(
        x: side * gap,
        w: w,
        h: h,
        z: z,
        wall: _walls[_rnd.nextInt(_walls.length)],
        roof: _roofs[_rnd.nextInt(_roofs.length)],
        lit: _rnd.nextInt(100) < 45,
        tank: _rnd.nextInt(100) < 35,
      );
      (side < 0 ? _left : _right).add(b);
    }
  }

  void paint(Canvas canvas, Projection p, double time) {
    final visible = <_Building>[..._left, ..._right]
        .where((b) => b.z - p.camZ > -2 && b.z - p.camZ < 48)
        .toList()
      ..sort((a, b) => b.z.compareTo(a.z)); // far first
    for (final b in visible) {
      _paintBuilding(canvas, p, b);
    }
    _paintLights(canvas, p, time);
  }

  void _paintBuilding(Canvas canvas, Projection p, _Building b) {
    final dz = b.z - p.camZ;
    final inner = b.x;
    final side = inner < 0 ? -1.0 : 1.0;
    final outer = inner + side * b.w;
    // rows dissolve into the haze a little earlier than the track does
    final fade = p.fadeAt(b.z - 12);
    final paint = Paint();

    // facade facing the track — seen at a grazing angle, so it stays plain
    canvas.drawPath(
      p.uprightQuad(inner, outer, b.z, 0, b.h),
      paint..color = _shade(b.wall, 0.88).withValues(alpha: fade),
    );
    // the side wall the camera actually looks at
    final wallX = inner - 0.02 * side;
    canvas.drawPath(
      p.wallQuad(wallX, b.z, b.z + _depth, 0, b.h),
      paint..color = b.wall.withValues(alpha: fade),
    );
    // roof slab
    canvas.drawPath(
      p.groundQuad(math.min(inner, outer), math.max(inner, outer), b.z,
          b.z + _depth, b.h),
      paint..color = b.roof.withValues(alpha: fade),
    );
    // parapet lip
    canvas.drawPath(
      p.uprightQuad(inner, outer, b.z - 0.02, b.h, b.h + 0.26),
      paint..color = _shade(b.roof, 1.08).withValues(alpha: fade),
    );

    if (dz < 34) {
      // windows on the side wall: two along z, one row per ~1.4 world units
      final rows = ((b.h - 1.4) / 1.4).floor().clamp(1, 4);
      for (var r = 0; r < rows; r++) {
        for (var c = 0; c < 2; c++) {
          final z0 = b.z + _depth * (0.10 + c * 0.46);
          final z1 = z0 + _depth * 0.30;
          final y0 = 1.05 + r * 1.4;
          final y1 = y0 + 0.8;
          if (y1 > b.h - 0.2) continue;
          final warm = b.lit ? true : (r + c).isEven;
          canvas.drawPath(
            p.wallQuad(wallX - 0.01 * side, z0, z1, y0, y1),
            paint
              ..color = (warm ? Pal.coin : _shade(b.wall, 0.66))
                  .withValues(alpha: 0.9 * fade),
          );
        }
      }
      // festival pennants strung along the wall
      final pennantY = math.min(b.h - 0.5, 3.0);
      for (var i = 0; i < 4; i++) {
        final z0 = b.z + _depth * (0.04 + i * 0.24);
        final z1 = z0 + _depth * 0.14;
        canvas.drawPath(
          p.wallQuad(wallX - 0.01 * side, z0, z1, pennantY - 0.16, pennantY),
          paint
            ..color =
                (i.isEven ? Pal.danger : Pal.accent).withValues(alpha: fade),
        );
      }
    }

    if (b.tank && dz < 36) {
      final cx = inner + (outer - inner) * 0.5;
      canvas.drawPath(
        p.uprightQuad(cx - 0.4, cx + 0.4, b.z + 1.1, b.h + 0.26, b.h + 0.98),
        paint..color = Pal.concrete.withValues(alpha: fade),
      );
      canvas.drawPath(
        p.groundQuad(cx - 0.4, cx + 0.4, b.z + 1.1, b.z + 1.9, b.h + 0.98),
        paint..color = _shade(Pal.concrete, 0.9).withValues(alpha: fade),
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

  static Color _shade(Color c, double f) => Color.fromARGB(
        (c.a * 255).round(),
        (c.r * 255 * f).round().clamp(0, 255),
        (c.g * 255 * f).round().clamp(0, 255),
        (c.b * 255 * f).round().clamp(0, 255),
      );
}
