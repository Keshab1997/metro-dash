import 'dart:math' as math;

import '../core/config.dart';
import '../entities/coin.dart';
import '../entities/obstacle.dart';
import '../entities/runner.dart';

/// All hit geometry in one file, so the rules can be read (and unit tested)
/// without touching a canvas (docs/TECH_ARCHITECTURE.md §2).
class CollisionSystem {
  const CollisionSystem._();

  static const _runnerHalfDepth = 0.34;

  /// A runner overlaps a lane when he is within half a lane of its centre.
  /// While changing lanes x is continuous, so the sweep is honest.
  static bool _inLane(Runner r, int lane) =>
      (r.x - Tune.laneX[lane]).abs() < 0.42;

  static bool _overlapsZ(Runner r, Obstacle o) =>
      r.z + _runnerHalfDepth > o.z && r.z - _runnerHalfDepth < o.z + o.length;

  /// The first obstacle the runner is inside right now, or null.
  static Obstacle? hit(Runner r, Iterable<Obstacle> obstacles) {
    for (final o in obstacles) {
      if (!_inLane(r, o.lane) || !_overlapsZ(r, o)) continue;
      switch (o.kind) {
        case ObstacleKind.barrierLow:
          if (r.y < o.height) return o;
        case ObstacleKind.cones:
          if (r.y < o.height) return o;
        case ObstacleKind.barrierHigh:
          if (!r.isRolling || r.height > o.gapUnder) return o;
        case ObstacleKind.train:
          return o; // no roof-riding in v1
      }
    }
    return null;
  }

  /// Mark obstacles the runner just cleared in an adjacent lane — used for the
  /// style bonus. Returns how many new near-misses were found.
  static int collectNearMisses(Runner r, Iterable<Obstacle> obstacles) {
    var found = 0;
    for (final o in obstacles) {
      if (o.passed) continue;
      if (o.z + o.length > r.z) continue;
      o.passed = true;
      final lateral = (r.x - Tune.laneX[o.lane]).abs();
      if (lateral > 0.42 && lateral < 1.0 && o.kind != ObstacleKind.cones) {
        found++;
      }
    }
    return found;
  }

  /// Coins picked up this frame (they are marked taken here).
  static List<Coin> pickup(Runner r, Iterable<Coin> coins) {
    final got = <Coin>[];
    final reach = r.isAirborne ? 1.0 : 0.85;
    for (final c in coins) {
      if (c.taken) continue;
      if (!_inLane(r, c.lane)) continue;
      if ((c.z - r.z).abs() > 0.55) continue;
      final dy = (c.y - (r.y + r.height * 0.5)).abs();
      if (dy < reach) {
        c.taken = true;
        got.add(c);
      }
    }
    return got;
  }

  /// Sorting key so the painter can draw far things first.
  static double depthKey(double z, double camZ) => math.max(0.001, z - camZ);
}
