import 'dart:ui';

import '../core/config.dart';
import '../entities/runner.dart';

/// Turns raw swipes/keys into at most one honoured intent, and never drops a
/// request the player reasonably made (docs/GAME_DESIGN.md §4 — feel rules).
class InputController {
  LaneIntent? _pending;
  double _pendingAt = -99;

  void queue(LaneIntent intent, double now) {
    // A newer intent replaces the old one: the player's latest wish wins.
    _pending = intent;
    _pendingAt = now;
  }

  /// Called once per frame, before the runner moves.
  void apply(Runner runner, double now) {
    final intent = _pending;
    if (intent == null) return;
    if (runner.intent(intent)) {
      _pending = null;
      return;
    }
    if (now - _pendingAt > Tune.inputBuffer) {
      _pending = null; // stale, forget it
    }
  }

  bool get hasPending => _pending != null;

  void clear() {
    _pending = null;
    _pendingAt = -99;
  }

  /// Map a drag delta to an intent — the one place the gesture geometry lives.
  static LaneIntent? fromDrag(Offset delta) {
    if (delta.distance < Tune.swipeThreshold) return null;
    if (delta.dx.abs() > delta.dy.abs()) {
      return delta.dx < 0 ? LaneIntent.left : LaneIntent.right;
    }
    return delta.dy < 0 ? LaneIntent.jump : LaneIntent.roll;
  }
}
