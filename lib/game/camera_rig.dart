import 'dart:math' as math;

import '../core/config.dart';

/// Chase camera that trails the runner down the track.
///
/// z follows the runner exactly (a lagging z drifts the hero up the screen and
/// makes the lane the eye reads ambiguous); x lags a little so lane changes
/// feel weighty instead of teleporting.
class CameraRig {
  double x = 0;
  double y = Tune.camHeight;
  double z = -Tune.camDist;
  double roll = 0;

  void follow(
      {required double runnerX, required double runnerZ, required double dt}) {
    z = runnerZ - Tune.camDist;
    final k = (dt * Tune.camXLag).clamp(0.0, 1.0);
    x += (runnerX * 0.24 - x) * k;
    final targetRoll = (runnerX - x) * -0.07;
    roll += (targetRoll - roll) * k;
  }

  void reset() {
    x = 0;
    y = Tune.camHeight;
    z = -Tune.camDist;
    roll = 0;
  }

  /// Vertical dip used on a hard landing.
  double dip = 0;

  void bump(double amount) => dip = math.max(dip, amount);

  void updateDip(double dt) {
    if (dip <= 0) return;
    dip = math.max(0, dip - dt * 2.2);
  }
}
