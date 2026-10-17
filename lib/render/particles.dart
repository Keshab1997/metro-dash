import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/assets.dart';
import '../core/palette.dart';
import '../game/projection.dart';

class Puff {
  Puff(this.x, this.y, this.z,
      {required this.life, required this.size, required this.color});

  double x;
  double y;
  double z;
  double t = 0;
  final double life;
  final double size;
  final Color color;
}

class Popup {
  Popup(this.text, this.x, this.y, this.z, {this.life = 0.85});

  final String text;
  final double x;
  double y; // rises as it fades
  final double z;
  final double life;
  double t = 0;
}

/// One impact burst: a sprite that pops, expands and fades at a world point.
class Burst {
  Burst(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
  double t = 0;
  static const double life = 0.55;
}

/// Dust, sparks, impact bursts and floating score numbers — the cheap half of
/// "feel".
class Particles {
  final List<Puff> puffs = <Puff>[];
  final List<Popup> popups = <Popup>[];
  final List<Burst> bursts = <Burst>[];

  final math.Random _rnd = math.Random(99);

  void dust(double x, double y, double z,
      {int n = 7, double spread = 0.4, double size = 0.2}) {
    for (var i = 0; i < n; i++) {
      final a = _rnd.nextDouble() * math.pi * 2;
      puffs.add(
        Puff(
          x + math.cos(a) * spread * 0.5,
          y + _rnd.nextDouble() * 0.25,
          z + math.sin(a) * spread * 0.25,
          life: 0.35 + _rnd.nextDouble() * 0.35,
          size: size * (0.6 + _rnd.nextDouble() * 0.8),
          color: Pal.haze,
        ),
      );
    }
  }

  void sparkle(double x, double y, double z, {int n = 6}) {
    for (var i = 0; i < n; i++) {
      final a = _rnd.nextDouble() * math.pi * 2;
      puffs.add(
        Puff(
          x + math.cos(a) * 0.2,
          y + math.sin(a) * 0.2,
          z,
          life: 0.25 + _rnd.nextDouble() * 0.25,
          size: 0.09,
          color: Pal.coin,
        ),
      );
    }
  }

  void popup(String text, double x, double y, double z) =>
      popups.add(Popup(text, x, y, z));

  /// A generated crash burst at the point of impact.
  void burst(double x, double y, double z) => bursts.add(Burst(x, y, z));

  void clear() {
    puffs.clear();
    popups.clear();
    bursts.clear();
  }

  void update(double dt) {
    for (final p in puffs) {
      p.t += dt;
      p.y += dt * 0.9;
    }
    puffs.removeWhere((p) => p.t >= p.life);
    for (final p in popups) {
      p.t += dt;
      p.y += dt * 1.1;
    }
    popups.removeWhere((p) => p.t >= p.life);
    for (final b in bursts) {
      b.t += dt;
    }
    bursts.removeWhere((b) => b.t >= Burst.life);
  }

  void paint(Canvas canvas, Projection p, Size size, GameAssets? assets) {
    final dust = assets?.dust;
    final crash = assets?.crash;
    if (crash != null) {
      for (final b in bursts) {
        final dz = b.z - p.camZ;
        if (dz < p.nearZ || dz > p.camZ + 30) continue;
        final pos = p.project(b.x, b.y, b.z);
        final k = (b.t / Burst.life).clamp(0.0, 1.0);
        // pop out fast, then fade: the classic impact curve
        final grow = 0.55 + 0.9 * math.sqrt(k);
        final h = 1.9 * pos.scale * grow;
        final w = h * crash.width / crash.height;
        canvas.drawImageRect(
          crash,
          Rect.fromLTWH(0, 0, crash.width.toDouble(), crash.height.toDouble()),
          Rect.fromCenter(center: pos.screen, width: w, height: h),
          Paint()
            ..colorFilter = ColorFilter.mode(
              Color.fromARGB(((1 - k) * 255).round(), 255, 255, 255),
              BlendMode.modulate,
            ),
        );
      }
    }
    final sorted = List<Puff>.from(puffs)..sort((a, b) => b.z.compareTo(a.z));
    for (final puff in sorted) {
      final dz = puff.z - p.camZ;
      if (dz < p.nearZ || dz > p.camZ + 26) continue;
      final pos = p.project(puff.x, puff.y, puff.z);
      final k = (puff.t / puff.life).clamp(0.0, 1.0);
      final r = puff.size * pos.scale * (0.55 + k * 0.9);
      if (dust != null) {
        // The generated dust sprite, faded out over its life and tinted by the
        // particle colour (sparkle particles stay pure colour discs).
        final paint = Paint()
          ..colorFilter = ColorFilter.mode(
            puff.color.withValues(alpha: (1 - k) * 0.8),
            BlendMode.modulate,
          );
        final h = r * 2.1;
        final w = h * dust.width / dust.height;
        canvas.drawImageRect(
          dust,
          Rect.fromLTWH(0, 0, dust.width.toDouble(), dust.height.toDouble()),
          Rect.fromCenter(center: pos.screen, width: w, height: h),
          paint,
        );
      } else {
        canvas.drawCircle(
          pos.screen,
          r,
          Paint()..color = puff.color.withValues(alpha: (1 - k) * 0.75),
        );
      }
    }
  }

  void paintPopups(Canvas canvas, Projection p) {
    for (final pop in popups) {
      final dz = pop.z - p.camZ;
      if (dz < p.nearZ || dz > p.camZ + 30) continue;
      final pos = p.project(pop.x, pop.y, pop.z);
      final k = (pop.t / pop.life).clamp(0.0, 1.0);
      final tp = TextPainter(
        text: TextSpan(
          text: pop.text,
          style: TextStyle(
            fontSize: math.max(12, 0.34 * pos.scale),
            fontWeight: FontWeight.w900,
            color: Pal.paper.withValues(alpha: 1 - k),
            shadows: <Shadow>[
              Shadow(
                  color: Pal.ink.withValues(alpha: 0.6 * (1 - k)),
                  blurRadius: 3,
                  offset: const Offset(0, 2)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos.screen - Offset(tp.width / 2, tp.height / 2));
    }
  }
}
