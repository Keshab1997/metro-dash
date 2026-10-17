import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/assets.dart';
import '../core/config.dart';
import '../core/palette.dart';
import '../entities/coin.dart';
import '../entities/obstacle.dart';
import '../entities/runner.dart';
import '../game/projection.dart';
import '../world/environment.dart';
import '../world/skyline.dart';
import '../world/track_builder.dart';
import 'particles.dart';

/// Everything one frame of painting needs, assembled by the game state.
class FrameView {
  FrameView({
    required this.size,
    required this.projection,
    required this.assets,
    required this.skyline,
    required this.track,
    required this.environment,
    required this.runner,
    required this.obstacles,
    required this.coins,
    required this.particles,
    required this.time,
    required this.speed,
    required this.shake,
    required this.flash,
  });

  final Size size;
  final Projection projection;
  final GameAssets? assets;
  final Skyline skyline;
  final TrackBuilder track;
  final Environment environment;
  final Runner runner;
  final List<Obstacle> obstacles;
  final List<Coin> coins;
  final Particles particles;
  final double time;
  final double speed;
  final double shake;
  final double flash;
}

/// Draws the world back-to-front: sky → track → city → obstacles → coins →
/// hero → particles. All geometry goes through Projection, so the painting
/// stays honest pseudo-3D.
class GamePainter extends CustomPainter {
  GamePainter(this.view);

  final FrameView view;

  @override
  void paint(Canvas canvas, Size size) {
    final p = view.projection;
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    if (view.shake > 0.001) {
      final s = view.shake * 9;
      canvas.translate(
          math.sin(view.time * 61) * s, math.cos(view.time * 47) * s * 0.7);
    }

    view.skyline.paint(canvas, size, p, view.assets);
    view.track.paint(canvas, size, p, view.assets);
    // The haze dissolves the far end of the ground -- so it has to go on
    // before the city, or it paints a white band straight across the
    // buildings and their lamp posts.
    _paintDistanceHaze(canvas, size, p);
    view.environment.paint(canvas, p, view.time, view.assets);
    _paintObstacles(canvas, p);
    _paintCoins(canvas, p);
    _paintRunner(canvas, p);
    view.particles.paint(canvas, p, size, view.assets);
    view.particles.paintPopups(canvas, p);
    _paintSpeedStreaks(canvas, size);
    canvas.restore();

    if (view.flash > 0.001) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color =
              Pal.paper.withValues(alpha: (view.flash * 0.45).clamp(0.0, 0.45)),
      );
    }
  }

  /// Air between the camera and the horizon: without it the far end of the
  /// track stops in a hard line instead of dissolving into the afternoon.
  void _paintDistanceHaze(Canvas canvas, Size size, Projection p) {
    final h = size.height;
    final top = p.horizonY - h * 0.012;
    final bottom = p.horizonY + h * 0.045;
    canvas.drawRect(
      Rect.fromLTRB(0, top, size.width, bottom),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Pal.haze.withValues(alpha: 0.26),
            Pal.haze.withValues(alpha: 0.13),
            Pal.haze.withValues(alpha: 0.0),
          ],
          stops: const <double>[0.0, 0.55, 1.0],
        ).createShader(Rect.fromLTRB(0, top, size.width, bottom)),
    );
  }

  // ---- obstacles -----------------------------------------------------------
  void _paintObstacles(Canvas canvas, Projection p) {
    final visible = view.obstacles
        .where((o) =>
            o.z + o.length > p.camZ + Tune.viewNear &&
            o.z < p.camZ + Tune.viewFar)
        .toList()
      ..sort((a, b) => b.z.compareTo(a.z));
    for (final o in visible) {
      _paintObstacle(canvas, p, o);
    }
  }

  /// Draws a sprite standing on the ground plane: bottom edge at y = 0,
  /// centred on `x`, `worldH` world units tall, aspect preserved.
  void _drawSprite(
      Canvas canvas, ui.Image image, double x, double z, double worldH,
      {double alpha = 1}) {
    final base = p0.project(x, 0, z);
    final h = worldH * base.scale;
    final w = h * image.width / image.height;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(base.screen.dx - w / 2, base.screen.dy - h, w, h),
      alpha >= 1
          ? Paint()
          : (Paint()
            ..color = Color.fromARGB((255 * alpha).round(), 255, 255, 255)),
    );
  }

  /// The projection currently being painted — set in `paint`, read by helpers.
  late Projection p0;

  void _paintObstacle(Canvas canvas, Projection p, Obstacle o) {
    final laneX = Tune.laneX[o.lane];
    final fade = p.fadeAt(o.z);
    final paint = Paint();
    p0 = p;

    final sprite = view.assets?.sprite(switch (o.kind) {
      // alternate the two generated gate variants so a level crossing never
      // looks copy-pasted
      ObstacleKind.barrierLow => o.id.isEven ? 'barrier_low' : 'barrier_low_2',
      ObstacleKind.barrierHigh => 'barrier_high',
      ObstacleKind.train => 'train',
      ObstacleKind.cones => 'cones',
    });
    if (sprite != null) {
      // The visual height is the obstacle's hitbox height, so what the player
      // sees is exactly what the collision rules use.
      final visualH = switch (o.kind) {
        ObstacleKind.barrierLow => 0.42,
        ObstacleKind.barrierHigh => 2.70,
        ObstacleKind.train => 1.85,
        ObstacleKind.cones => 0.62,
      };
      final sway = o.kind == ObstacleKind.barrierHigh
          ? math.sin(view.time * 1.7 + o.id) * 0.05
          : 0.0;
      _drawSprite(canvas, sprite, laneX + sway, o.z, visualH, alpha: fade);
      // ground contact shadow
      final base = p.project(laneX, 0, o.z);
      canvas.drawOval(
        Rect.fromCenter(
          center: base.screen,
          width: visualH * base.scale * 0.9,
          height: visualH * base.scale * 0.22,
        ),
        paint..color = const Color(0x330D2420),
      );
      return;
    }

    switch (o.kind) {
      case ObstacleKind.barrierLow:
        for (final side in const <double>[-1, 1]) {
          final x = laneX + side * 0.44;
          canvas.drawPath(
            p.uprightQuad(x - 0.05, x + 0.05, o.z, 0, 0.98),
            paint..color = Pal.concreteDark.withValues(alpha: fade),
          );
        }
        const stripes = 5;
        for (var i = 0; i < stripes; i++) {
          final x0 = laneX - 0.44 + (0.88 / stripes) * i;
          canvas.drawPath(
            p.uprightQuad(x0, x0 + 0.88 / stripes, o.z - 0.03, 0.52, 0.96),
            paint
              ..color =
                  (i.isEven ? Pal.danger : Pal.paper).withValues(alpha: fade),
          );
        }
        break;

      case ObstacleKind.barrierHigh:
        final sway = math.sin(view.time * 1.7 + o.id) * 0.05;
        for (final side in const <double>[-1, 1]) {
          final x = laneX + side * 0.5;
          canvas.drawPath(
            p.uprightQuad(x - 0.045, x + 0.045, o.z + sway, 0, 2.7),
            paint..color = Pal.railDark.withValues(alpha: fade),
          );
        }
        canvas.drawPath(
          p.uprightQuad(laneX - 0.5, laneX + 0.5, o.z + sway, 1.0, 2.6),
          paint..color = Pal.accent.withValues(alpha: fade),
        );
        canvas.drawPath(
          p.uprightQuad(
              laneX - 0.5, laneX + 0.5, o.z + sway - 0.02, 1.42, 1.86),
          paint..color = Pal.paper.withValues(alpha: fade),
        );
        break;

      case ObstacleKind.train:
        canvas.drawPath(
          p.uprightQuad(laneX - 0.47, laneX + 0.47, o.z, 0, 2.5),
          paint..color = Pal.wallTeal.withValues(alpha: fade),
        );
        // windscreen
        canvas.drawPath(
          p.uprightQuad(laneX - 0.38, laneX + 0.38, o.z - 0.03, 1.45, 2.15),
          paint..color = Pal.railDark.withValues(alpha: fade),
        );
        // roof cap + skirt
        canvas.drawPath(
          p.uprightQuad(laneX - 0.5, laneX + 0.5, o.z - 0.03, 2.42, 2.55),
          paint..color = Pal.paper.withValues(alpha: fade),
        );
        canvas.drawPath(
          p.uprightQuad(laneX - 0.5, laneX + 0.5, o.z - 0.03, 0, 0.45),
          paint..color = Pal.roofBlue.withValues(alpha: fade),
        );
        // headlights
        for (final side in const <double>[-1, 1]) {
          final pos = p.project(laneX + side * 0.26, 0.75, o.z - 0.05);
          canvas.drawOval(
            Rect.fromCenter(
              center: pos.screen,
              width: 0.17 * pos.scale,
              height: 0.13 * pos.scale,
            ),
            paint..color = Pal.coin.withValues(alpha: 0.9 * fade),
          );
        }
        // destination board
        final board = p.project(laneX, 2.28, o.z - 0.05);
        canvas.drawRect(
          Rect.fromCenter(
            center: board.screen,
            width: 0.6 * board.scale,
            height: 0.2 * board.scale,
          ),
          paint..color = Pal.ink.withValues(alpha: 0.85 * fade),
        );
        break;

      case ObstacleKind.cones:
        for (final dx in const <double>[-0.3, 0, 0.3]) {
          final x = laneX + dx;
          final left = p.project(x - 0.14, 0, o.z);
          final right = p.project(x + 0.14, 0, o.z);
          final apex = p.project(x, 0.55, o.z);
          canvas.drawPath(
            Path()
              ..moveTo(left.screen.dx, left.screen.dy)
              ..lineTo(right.screen.dx, right.screen.dy)
              ..lineTo(apex.screen.dx, apex.screen.dy)
              ..close(),
            paint..color = Pal.accent.withValues(alpha: fade),
          );
          final s0 = p.project(x - 0.085, 0.24, o.z);
          final s1 = p.project(x + 0.085, 0.24, o.z);
          final s2 = p.project(x + 0.05, 0.33, o.z);
          final s3 = p.project(x - 0.05, 0.33, o.z);
          canvas.drawPath(
            Path()
              ..moveTo(s0.screen.dx, s0.screen.dy)
              ..lineTo(s1.screen.dx, s1.screen.dy)
              ..lineTo(s2.screen.dx, s2.screen.dy)
              ..lineTo(s3.screen.dx, s3.screen.dy)
              ..close(),
            paint..color = Pal.paper.withValues(alpha: fade),
          );
        }
        break;
    }
  }

  // ---- coins ---------------------------------------------------------------
  void _paintCoins(Canvas canvas, Projection p) {
    final paint = Paint();
    final coinSprite = view.assets?.sprite(GameAssets.coinKey);
    for (final c in view.coins) {
      if (c.taken) continue;
      final dz = c.z - p.camZ;
      if (dz < Tune.viewNear || dz > Tune.viewFar) continue;
      final pos = p.project(Tune.laneX[c.lane], c.y, c.z);
      final fade = p.fadeAt(c.z);
      final r = 0.23 * pos.scale;

      if (coinSprite != null) {
        canvas.drawCircle(
          pos.screen,
          r * 1.5,
          paint..color = Pal.coin.withValues(alpha: 0.10 * fade),
        );
        // A real spin: the disc turns on its vertical axis, squeezing to a
        // sliver and back and mirroring for the back of the turn. Two sprites
        // that both render face-on cannot do that -- a coin line just read as
        // one gold caterpillar.
        final phase = view.time * 5.6 + c.z * 1.35;
        final turn = math.cos(phase);
        final squeeze = 0.16 + 0.84 * turn.abs();
        final h = r * 1.72;
        final w = h * coinSprite.width / coinSprite.height * squeeze;
        canvas.save();
        if (turn < 0) {
          // mirror about the coin's own centre: shows its back for half a turn
          canvas.translate(pos.screen.dx * 2, 0);
          canvas.scale(-1, 1);
        }
        canvas.drawImageRect(
          coinSprite,
          Rect.fromLTWH(
              0, 0, coinSprite.width.toDouble(), coinSprite.height.toDouble()),
          Rect.fromCenter(center: pos.screen, width: w, height: h),
          fade >= 0.99
              ? Paint()
              : (Paint()
                ..color = Color.fromARGB((255 * fade).round(), 255, 255, 255)),
        );
        canvas.restore();
        continue;
      }

      final spin = math.sin(view.time * 4.6 + c.z * 0.8).abs();
      final w = (r * (0.25 + 0.75 * spin)).clamp(r * 0.2, r);
      final rect =
          Rect.fromCenter(center: pos.screen, width: w * 2, height: r * 2);
      canvas.drawOval(
        rect.inflate(r * 0.45),
        paint..color = Pal.coin.withValues(alpha: 0.16 * fade),
      );
      canvas.drawOval(
          rect, paint..color = Pal.coinDeep.withValues(alpha: fade));
      canvas.drawOval(rect.deflate(r * 0.16),
          paint..color = Pal.coin.withValues(alpha: fade));
      canvas.drawOval(
        rect.deflate(r * 0.42),
        paint..color = Pal.coinDeep.withValues(alpha: 0.65 * fade),
      );
    }
  }

  // ---- the hero ------------------------------------------------------------
  void _paintRunner(Canvas canvas, Projection p) {
    final r = view.runner;
    final ground = p.project(r.x, 0, r.z);
    final shrink = 1 / (1 + r.y * 0.75);
    canvas.drawOval(
      Rect.fromCenter(
        center: ground.screen,
        width: 0.58 * ground.scale * shrink,
        height: 0.19 * ground.scale * shrink,
      ),
      Paint()..color = const Color(0x4D0D2420),
    );

    final feet = p.project(r.x, r.y, r.z);
    canvas.save();
    canvas.translate(feet.screen.dx, feet.screen.dy);

    if (r.isRolling) {
      // placeholder roll: a forward tumble reads better than a slide
      final half = 0.42 * feet.scale;
      canvas.translate(0, -half);
      canvas.rotate(-r.rollProgress * math.pi * 2);
      canvas.translate(0, half);
    } else if (!r.isAirborne) {
      canvas.translate(0, math.sin(r.stride * math.pi * 2) * 0.03 * feet.scale);
    }

    final squash = r.squash.clamp(0.75, 1.15);
    canvas.scale(1 + (1 - squash) * 0.5, squash);

    final assets = view.assets;
    final dying = !r.alive && assets?.hitFrame != null;
    final ui.Image? image = assets == null
        ? null
        : dying
            ? assets.hitFrame
            : r.isAirborne
                ? assets.airFrame
                : r.isRolling
                    ? (assets.rollFrame ?? assets.airFrame)
                    : assets
                        .runFrames[r.runFrameIndexFor(assets.runFrames.length)];

    if (image != null) {
      final h = Tune.runnerHeight * feet.scale * (r.isRolling ? 0.8 : 1.03);
      final w = h * image.width / image.height;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(-w / 2, -h, w, h),
        Paint(),
      );
    } else {
      _paintFallbackRunner(canvas, feet.scale);
    }
    canvas.restore();
  }

  /// If a sprite fails to load, the hero still shows up as a simple figure.
  void _paintFallbackRunner(Canvas canvas, double scale) {
    final h = Tune.runnerHeight * scale;
    final w = 0.52 * scale;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-w / 2, -h * 0.62, w, h * 0.62),
          Radius.circular(w * 0.3)),
      Paint()..color = Pal.accent,
    );
    canvas.drawCircle(
        Offset(0, -h * 0.78), w * 0.3, Paint()..color = Pal.hoodie);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-w * 0.42, -h * 0.42, w * 0.84, h * 0.42),
          Radius.circular(w * 0.2)),
      Paint()..color = Pal.railDark,
    );
  }

  // ---- speed streaks -------------------------------------------------------
  void _paintSpeedStreaks(Canvas canvas, Size size) {
    final streak = view.assets?.sprite('speed_streak');
    final intensity0 =
        ((view.speed - 17) / (Tune.speedCap - 17)).clamp(0.0, 1.0);
    if (streak != null && intensity0 > 0) {
      final t0 = view.time * 3.4;
      for (var i = 0; i < 8; i++) {
        final edge = i.isEven;
        final k = ((i * 0.37 + t0) % 1.0);
        final y = size.height * (0.55 + k * 0.42);
        final w = size.width * (0.16 + 0.20 * intensity0) * (0.6 + k * 0.6);
        final h = w * streak.height / streak.width;
        final x = edge ? -w * 0.15 : size.width - w * 0.85;
        canvas.drawImageRect(
          streak,
          Rect.fromLTWH(
              0, 0, streak.width.toDouble(), streak.height.toDouble()),
          Rect.fromLTWH(x, y, w, h),
          Paint()
            ..colorFilter = ColorFilter.mode(
              Color.fromARGB(
                (210 * intensity0 * (0.35 + k * 0.65)).round(),
                255,
                255,
                255,
              ),
              BlendMode.modulate,
            ),
        );
      }
      return;
    }
    final intensity =
        ((view.speed - 17) / (Tune.speedCap - 17)).clamp(0.0, 1.0);
    if (intensity <= 0) return;
    final paint = Paint()
      ..color = Pal.paper.withValues(alpha: 0.16 * intensity)
      ..strokeWidth = 2;
    final t = view.time * 3.4;
    for (var i = 0; i < 10; i++) {
      final edge = i.isEven; // alternate sides
      final k = ((i * 0.37 + t) % 1.0);
      final y = size.height * (0.62 + k * 0.34);
      final len = size.width * (0.10 + 0.16 * intensity) * (0.5 + k);
      final x0 = edge ? -size.width * 0.02 : size.width * 1.02;
      final x1 = edge ? x0 + len : x0 - len;
      canvas.drawLine(Offset(x0, y), Offset(x1, y + len * 0.10), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => true;
}
