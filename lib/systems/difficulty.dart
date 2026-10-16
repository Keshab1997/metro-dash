import 'dart:math' as math;

import '../core/config.dart';
import '../entities/obstacle.dart';

/// The difficulty curve, pure functions only — so it can be unit tested
/// without a game loop (docs/GAME_DESIGN.md §5.3).
class Difficulty {
  const Difficulty._();

  static double speedAt(double metres) =>
      math.min(Tune.speedCap, Tune.speedStart + metres * Tune.speedRamp);

  /// Metres between event groups. Shrinks with distance, but never below the
  /// reaction floor of the current line speed.
  static double gapAt(double metres, double speed) {
    final curve = 24.0 - metres / 260.0;
    return math.max(math.max(curve, 11.0), speed * Tune.minReact);
  }

  /// Two lanes may only be blocked once the player has warmed up.
  static int maxBlockedLanes(double metres) => metres < 250 ? 1 : 2;

  /// Which obstacles exist yet — a gentle introduction, then the full set.
  static ObstacleKind pickKind(double metres, math.Random rnd) {
    final pool = <ObstacleKind>[ObstacleKind.barrierLow, ObstacleKind.cones];
    if (metres > 150) pool.add(ObstacleKind.barrierHigh);
    if (metres > 300) pool.add(ObstacleKind.train);
    return pool[rnd.nextInt(pool.length)];
  }
}
