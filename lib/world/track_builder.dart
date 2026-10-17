import 'dart:math' as math;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/assets.dart';
import '../core/config.dart';
import '../core/palette.dart';
import '../game/projection.dart';
import 'textured_surface.dart';

/// The running surface, built like a real one: textured ballast and banks,
/// sleepers with a bevel, and rails with a web, a head and a specular line.
/// Owner: worker A (Batch 1).
class TrackBuilder {
  final Paint _paint = Paint()..isAntiAlias = true;

  // ---- rail profile (world units) -----------------------------------------
  static const double _railHalfWidth = 0.052;
  static const double _webTop = 0.10;
  static const double _headTop = 0.145;

  static const Color _railHead = Color(0xFF8A949B);
  static const Color _railShine = Color(0xFFE8F1F4);
  static const Color _sleeperBase = Color(0xFF7A6650);
  static const Color _sleeperLight = Color(0xFF97806A);
  static const Color _sleeperDark = Color(0xFF5C4C3B);

  void paint(Canvas canvas, Size size, Projection p, GameAssets? assets) {
    final near = p.nearZ;
    final far = p.camZ + Tune.viewFar;
    final shoulder = Tune.trackHalf + 0.42;
    const bank = 10.0;

    final grass = assets?.sprite(GameAssets.grassKey);
    final concrete = assets?.sprite(GameAssets.concreteKey);
    final ballast = assets?.sprite(GameAssets.ballastKey);

    // ---- bank + shoulder ---------------------------------------------------
    if (grass != null) {
      TexturedSurface.groundBand(
        canvas,
        p,
        grass,
        x0: -bank,
        x1: -shoulder,
        y: 0,
        pxPerUnit: 150,
        tint: const Color(0xFFEDE6D6),
      );
      TexturedSurface.groundBand(
        canvas,
        p,
        grass,
        x0: shoulder,
        x1: bank,
        y: 0,
        pxPerUnit: 150,
        tint: const Color(0xFFEDE6D6),
      );
    } else {
      _fill(canvas, p, -bank, -shoulder, 0, near, far, Pal.grassDeep);
      _fill(canvas, p, shoulder, bank, 0, near, far, Pal.grassDeep);
    }

    // ---- ballast bed -------------------------------------------------------
    _fill(canvas, p, -shoulder, shoulder, 0.015, near, far,
        const Color(0xFF6B5F52));
    if (ballast != null) {
      TexturedSurface.groundBand(
        canvas,
        p,
        ballast,
        x0: -Tune.trackHalf,
        x1: Tune.trackHalf,
        y: 0.03,
        pxPerUnit: 210,
        tint: const Color(0xFFF3E7D8),
      );
    } else {
      _fill(
        canvas,
        p,
        -Tune.trackHalf,
        Tune.trackHalf,
        0.03,
        near,
        far,
        Pal.ballastDark,
      );
    }

    // ---- sleepers ----------------------------------------------------------
    final sleeperEnd = math.min(far, p.camZ + Tune.sleeperReach);
    final spacing = Tune.sleeperSpacing;
    final firstIndex = (sleeperEnd / spacing).floor();
    for (var i = firstIndex; i > 0; i--) {
      final z = i * spacing;
      if (z < near) continue;
      // a deterministic per-sleeper shade: worn wood, not a printed pattern
      final jitter = (math.sin(i * 12.9898) * 43758.5453).frac();
      final base = Color.lerp(_sleeperBase, _sleeperLight, jitter * 0.65)!;
      final half = Tune.trackHalf - 0.03;
      // body
      _fill(canvas, p, -half, half, 0.05, z, z + 0.34, base);
      // front bevel catches the sun, the back edge falls into shadow
      _fill(canvas, p, -half, half, 0.052, z, z + 0.07, _sleeperLight);
      _fill(canvas, p, -half, half, 0.052, z + 0.26, z + 0.34, _sleeperDark);
    }

    // ---- rails -------------------------------------------------------------
    for (final lane in Tune.laneX) {
      for (final side in const <double>[-1, 1]) {
        final x = lane + side * (Tune.laneGauge / 2);
        // contact shadow on the ballast
        _fill(
          canvas,
          p,
          x - 0.13,
          x + 0.13,
          0.035,
          near,
          far,
          const Color(0x33000000),
        );
        // web: the vertical face we actually look at from behind
        _railFace(canvas, p, x - _railHalfWidth, x + _railHalfWidth, near, far);
        // head: a touch wider than the web, brighter, with a specular line
        _fill(
          canvas,
          p,
          x - _railHalfWidth * 1.25,
          x + _railHalfWidth * 1.25,
          _headTop,
          near,
          far,
          _railHead,
        );
        final headTex = assets?.sprite(GameAssets.railHeadKey);
        if (headTex != null) {
          TexturedSurface.groundBand(
            canvas,
            p,
            headTex,
            x0: x - _railHalfWidth * 1.25,
            x1: x + _railHalfWidth * 1.25,
            y: _headTop + 0.002,
            pxPerUnit: 900,
            tint: const Color(0xFFF6FBFF),
          );
        } else {
          _fill(
            canvas,
            p,
            x - 0.012,
            x + 0.012,
            _headTop + 0.002,
            near,
            far,
            _railShine,
          );
        }
      }
    }

    // ---- track-side furniture ---------------------------------------------
    _trackSideProps(canvas, p, assets);

    // ---- parapet + coping --------------------------------------------------
    final wallFar = p.camZ + Tune.viewFar;
    for (final side in const <double>[-1, 1]) {
      final x = side * (shoulder + 0.2);
      if (concrete != null) {
        TexturedSurface.wallBand(
          canvas,
          p,
          concrete,
          x: x,
          yBottom: 0,
          yTop: 0.62,
          pxPerUnit: 95,
          farDz: wallFar - p.camZ,
          tint: const Color(0xFFF4EEE2),
        );
      }
      _fill(
        canvas,
        p,
        x - 0.16,
        x + 0.16,
        0.64,
        near,
        wallFar,
        const Color(0xFFEDE6D8),
      );
      _fill(canvas, p, x - 0.16, x + 0.05, 0.645, near, wallFar, Pal.paper);
    }
  }

  /// The inner face of a rail, lit from above and lost in shadow underneath.
  void _railFace(Canvas canvas, Projection p, double x0, double x1, double near,
      double far) {
    final a = p.project(x0, _webTop, far);
    final b = p.project(x1, _webTop, far);
    final c = p.project(x1, 0.02, near);
    final d = p.project(x0, 0.02, near);
    _paint
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const <Color>[Color(0xFF6E777E), Color(0xFF3A4247)],
      ).createShader(Rect.fromPoints(a.screen, c.screen))
      ..style = PaintingStyle.fill;
    canvas.drawPath(
      Path()
        ..moveTo(a.screen.dx, a.screen.dy)
        ..lineTo(b.screen.dx, b.screen.dy)
        ..lineTo(c.screen.dx, c.screen.dy)
        ..lineTo(d.screen.dx, d.screen.dy)
        ..close(),
      _paint,
    );
    _paint.shader = null;
  }

  /// Signal masts, catenary poles and kilometre markers, spaced down the line.
  /// They are the cheapest way to make the corridor read as a real railway.
  void _trackSideProps(Canvas canvas, Projection p, GameAssets? assets) {
    final signal = assets?.sprite('prop_signal');
    final catenary = assets?.sprite('prop_catenary');
    final marker = assets?.sprite('prop_marker');
    if (signal == null && catenary == null && marker == null) return;

    const signalSpacing = 62.0;
    const catenarySpacing = 26.0;
    const markerSpacing = 18.0;
    final startDz = 4.0;
    final farDz = Tune.viewFar;

    void draw(
        ui.Image sprite, double x, double z, double worldH, double alpha) {
      if (alpha <= 0.03) return;
      final base = p.project(x, 0, z);
      final h = worldH * base.scale;
      final w = h * sprite.width / sprite.height;
      canvas.drawImageRect(
        sprite,
        Rect.fromLTWH(0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
        Rect.fromLTWH(base.screen.dx - w / 2, base.screen.dy - h, w, h),
        alpha >= 0.99
            ? Paint()
            : (Paint()
              ..color = Color.fromARGB((255 * alpha).round(), 255, 255, 255)),
      );
    }

    if (catenary != null) {
      for (var dz = startDz; dz < farDz; dz += catenarySpacing) {
        final z = p.camZ + dz;
        draw(catenary, -(Tune.trackHalf + 0.75), z, 5.6, p.fadeAt(z) * 0.95);
        draw(catenary, (Tune.trackHalf + 0.75), z + catenarySpacing / 2, 5.6,
            p.fadeAt(z) * 0.95);
      }
    }
    if (signal != null) {
      for (var dz = startDz + 18; dz < farDz; dz += signalSpacing) {
        final z = p.camZ + dz;
        draw(signal, (Tune.trackHalf + 0.5), z, 3.4, p.fadeAt(z));
      }
    }
    if (marker != null) {
      for (var dz = startDz + 6; dz < farDz * 0.6; dz += markerSpacing) {
        final z = p.camZ + dz;
        draw(marker, -(Tune.trackHalf + 0.42), z, 0.8, p.fadeAt(z));
      }
    }
  }

  void _fill(
    Canvas canvas,
    Projection p,
    double x0,
    double x1,
    double y,
    double zNear,
    double zFar,
    Color color,
  ) {
    _paint
      ..shader = null
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawPath(p.groundQuad(x0, x1, zNear, zFar, y), _paint);
  }
}

extension _Frac on double {
  double frac() => this - floorToDouble();
}
