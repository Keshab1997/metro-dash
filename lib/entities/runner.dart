import 'dart:math' as math;

import '../core/config.dart';

/// What the player asked for this frame.
enum LaneIntent { left, right, jump, roll }

/// The hero. Frozen interface for worker B (docs/TECH_ARCHITECTURE.md §2):
/// `intent(LaneIntent)`, `isRolling`, `height`, `die()`, `reset()`.
class Runner {
  double x = 0; // world x — interpolated between lanes
  double y = 0; // height above the rail head
  double z = 0; // distance travelled, in world units
  int lane = 1; // 0 | 1 | 2

  double _fromX = 0;
  double _toX = 0;
  double _laneT = 1; // 0..1 within a lane change
  double _air = -1; // < 0 = grounded
  double _roll = -1;

  /// 1 = neutral. < 1 = squashed (landing, crouch), > 1 = stretched (take-off).
  double squash = 1;
  double stride = 0; // animation phase for the run cycle
  bool alive = true;

  bool get isAirborne => _air >= 0;
  bool get isRolling => _roll >= 0;

  /// Hitbox height — a rolling hero is half his standing height.
  double get height => isRolling ? Tune.rollHeight : Tune.runnerHeight;

  double get jumpT => _air < 0 ? 0 : (_air / Tune.jumpAirtime).clamp(0.0, 1.0);

  /// 0 → 1 across a roll: the painter spins the sprite with this.
  double get rollProgress =>
      isRolling ? (_roll / Tune.rollDuration).clamp(0.0, 1.0) : 0;

  /// Which run frame is showing. [frameCount] comes from the loaded sprite
  /// list, so adding frames later needs no change here.
  int runFrameIndexFor(int frameCount) {
    if (frameCount <= 1) return 0;
    return (stride * frameCount).floor().abs() % frameCount;
  }

  void reset() {
    x = 0;
    y = 0;
    z = 0;
    lane = 1;
    _fromX = 0;
    _toX = 0;
    _laneT = 1;
    _air = -1;
    _roll = -1;
    squash = 1;
    stride = 0;
    alive = true;
  }

  /// Returns false when the request cannot be honoured right now — the input
  /// controller then keeps it buffered for [Tune.inputBuffer] seconds.
  bool intent(LaneIntent i) {
    switch (i) {
      case LaneIntent.left:
      case LaneIntent.right:
        if (_laneT < 1) return false; // one lane step at a time
        final next = (lane + (i == LaneIntent.left ? -1 : 1)).clamp(0, 2);
        if (next == lane) return false;
        lane = next;
        _fromX = x;
        _toX = Tune.laneX[lane];
        _laneT = 0;
        squash = 0.93;
        return true;
      case LaneIntent.jump:
        if (isAirborne || !alive) return false;
        _air = 0;
        _roll = -1;
        squash = 0.85;
        return true;
      case LaneIntent.roll:
        if (isAirborne || isRolling || !alive) return false;
        _roll = 0;
        squash = 0.9;
        return true;
    }
  }

  void update(double dt, double speed) {
    z += speed * dt;

    if (_laneT < 1) {
      _laneT = (_laneT + dt / Tune.laneChange).clamp(0.0, 1.0);
      final e = 1 - math.pow(1 - _laneT, 3).toDouble(); // easeOutCubic
      x = _fromX + (_toX - _fromX) * e;
    } else {
      x = Tune.laneX[lane];
    }

    if (isAirborne) {
      _air += dt;
      y = math.sin((_air / Tune.jumpAirtime) * math.pi) * Tune.jumpApex;
      if (_air >= Tune.jumpAirtime) {
        _air = -1;
        y = 0;
        squash = 0.84; // landing impact — the painter eases it back to 1
      }
    }

    if (isRolling) {
      _roll += dt;
      if (_roll >= Tune.rollDuration) _roll = -1;
    }

    squash += (1 - squash) * math.min(1, dt * 9);
    // ~2 cycles a second at cruising speed. The old factor gave 7 a second,
    // which flickered through the cycle so fast the legs read as flapping.
    stride += dt * (1.05 + speed * 0.055);
  }

  void die() => alive = false;
}
