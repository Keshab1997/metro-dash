import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/palette.dart';
import '../game/projection.dart';

/// The running surface: grass banks, ballast bed, sleepers, six rails and the
/// concrete parapets. Owner: worker A (Batch 1).
class TrackBuilder {
  final Paint _ballastBed = Paint()..color = Pal.concreteDark;
  final Paint _sleeper = Paint()..color = Pal.ballast;
  final Paint _shoulder = Paint()..color = Pal.ballastDark;
  final Paint _grass = Paint()..color = Pal.grass;
  final Paint _grassDeep = Paint()..color = Pal.grassDeep;
  final Paint _railBody = Paint()..color = Pal.railDark;
  final Paint _railTop = Paint()..color = Pal.railSteel;
  final Paint _railShine = Paint()..color = Pal.railShine;
  final Paint _parapetFace = Paint()..color = Pal.concrete;
  final Paint _parapetTop = Paint()..color = Pal.paper;

  void paint(Canvas canvas, Size size, Projection p) {
    final near = p.nearZ;
    final far = p.camZ + Tune.viewFar;
    final shoulder = Tune.trackHalf + 0.45;
    const bank = 9.5;

    // ---- ground either side of the track ----------------------------------
    canvas.drawPath(p.groundQuad(-bank, -shoulder, near, far, 0), _grassDeep);
    canvas.drawPath(p.groundQuad(shoulder, bank, near, far, 0), _grassDeep);
    canvas.drawPath(
        p.groundQuad(-bank, -shoulder * 0.65, near, far, 0.01), _grass);
    canvas.drawPath(
        p.groundQuad(shoulder * 0.65, bank, near, far, 0.01), _grass);

    // ---- ballast bed -------------------------------------------------------
    canvas.drawPath(
        p.groundQuad(-shoulder, shoulder, near, far, 0.02), _shoulder);
    canvas.drawPath(
        p.groundQuad(-Tune.trackHalf, Tune.trackHalf, near, far, 0.03),
        _ballastBed);

    // ---- sleepers: far → near so overlaps resolve correctly ----------------
    final sleeperEnd = math.min(far, p.camZ + Tune.sleeperReach);
    final first =
        (sleeperEnd / Tune.sleeperSpacing).floor() * Tune.sleeperSpacing;
    for (double z = first; z > near; z -= Tune.sleeperSpacing) {
      canvas.drawPath(
        p.groundQuad(
            -Tune.trackHalf + 0.06, Tune.trackHalf - 0.06, z, z + 0.32, 0.045),
        _sleeper,
      );
    }

    // ---- six rails ---------------------------------------------------------
    for (final lane in Tune.laneX) {
      for (final side in const <double>[-1, 1]) {
        final x = lane + side * (Tune.laneGauge / 2);
        canvas.drawPath(
            p.groundQuad(x - 0.055, x + 0.055, near, far, 0.10), _railBody);
        canvas.drawPath(
            p.groundQuad(x - 0.030, x + 0.030, near, far, 0.12), _railTop);
        canvas.drawPath(
            p.groundQuad(x - 0.010, x + 0.010, near, far, 0.135), _railShine);
      }
    }

    // ---- parapet walls flanking the corridor ------------------------------
    final wallFar = p.camZ + Tune.sleeperReach;
    for (final side in const <double>[-1, 1]) {
      final x = side * (shoulder + 0.12);
      canvas.drawPath(p.wallQuad(x, near, wallFar, 0, 0.62), _parapetFace);
      canvas.drawPath(
        p.groundQuad(x - 0.14, x + 0.14, near, wallFar, 0.62),
        _parapetTop,
      );
    }
  }
}
