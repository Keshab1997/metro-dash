import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/assets.dart';
import '../core/palette.dart';
import '../game/projection.dart';

/// Sky, sun, distant hills and the AI-generated city backdrop.
/// Owner: worker A (Batch 1) — parallax depth lives here.
class Skyline {
  double _time = 0;

  void update(double dt) => _time += dt;

  void paint(Canvas canvas, Size size, Projection p, GameAssets? assets) {
    final w = size.width;
    final h = size.height;
    final horizon = p.horizonY;

    // ---- sky ---------------------------------------------------------------
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, horizon + h * 0.14),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const <Color>[Pal.skyTop, Pal.horizonWarm, Pal.sunGlow],
          stops: const <double>[0.0, 0.70, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, horizon + h * 0.10)),
    );

    // ---- sun + glow --------------------------------------------------------
    final sun = Offset(w * 0.30, horizon - h * 0.030);
    final glow = h * 0.19;
    canvas.drawCircle(
      sun,
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Pal.sunGlow.withValues(alpha: 0.80),
            Pal.sunGlow.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: sun, radius: glow)),
    );
    canvas.drawCircle(sun, h * 0.026, Paint()..color = const Color(0xFFFFF3DA));

    // ---- distant hills, two tones, very cheap ------------------------------
    canvas.drawPath(
      Path()
        ..moveTo(0, horizon + h * 0.012)
        ..quadraticBezierTo(
            w * 0.22, horizon - h * 0.055, w * 0.46, horizon + h * 0.008)
        ..quadraticBezierTo(
            w * 0.72, horizon - h * 0.045, w, horizon + h * 0.014)
        ..lineTo(w, horizon + h * 0.10)
        ..lineTo(0, horizon + h * 0.10)
        ..close(),
      Paint()..color = Pal.grassDeep.withValues(alpha: 0.55),
    );

    // ---- the city backdrop -------------------------------------------------
    if (assets != null) {
      final iw = assets.skyline.width.toDouble();
      final ih = assets.skyline.height.toDouble();
      final targetW = w * 1.14;
      final targetH = targetW * ih / iw;
      // a slow drift, wrapped inside a few pixels so no seam ever shows
      final drift = math.sin(_time * 0.06) * 9;
      // The band ends exactly at the horizon: the ground plane (and its rails)
      // takes over below, so the image can never show a cut-off edge on the
      // running surface.
      final rect = Rect.fromLTWH(
        -w * 0.07 + drift,
        horizon - targetH + h * 0.012,
        targetW,
        targetH,
      );
      // Feathered edges: the generated image must not hand the eye a straight
      // seam where it meets the painted sky or the haze over the tracks.
      canvas.saveLayer(rect.inflate(2), Paint());
      canvas.drawImageRect(
          assets.skyline, Rect.fromLTWH(0, 0, iw, ih), rect, Paint());
      canvas.drawRect(
        rect,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const <Color>[
              Color(0x00FFFFFF),
              Color(0xFFFFFFFF),
              Color(0xFFFFFFFF),
              Color(0x00FFFFFF),
            ],
            stops: const <double>[0.0, 0.10, 0.62, 1.0],
          ).createShader(rect),
      );
      canvas.restore();
    }

    // ---- horizon haze: the far world dissolves into warm air ---------------
    canvas.drawRect(
      Rect.fromLTWH(0, horizon - h * 0.02, w, h * 0.12),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Pal.haze.withValues(alpha: 0.0),
            Pal.haze.withValues(alpha: 0.9),
          ],
        ).createShader(Rect.fromLTWH(0, horizon - h * 0.02, w, h * 0.12)),
    );
  }
}
