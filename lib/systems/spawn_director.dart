import 'dart:math' as math;

import '../core/config.dart';
import '../entities/coin.dart';
import '../entities/obstacle.dart';
import 'difficulty.dart';

/// Decides what appears ahead. Owner: worker C (Batch 1) — the fairness law
/// below is the part that must never regress:
///
///   * never block all three lanes; at any z at least one lane is open,
///   * events are separated by at least `speed * minReact` metres, so a lane
///     change is always physically possible,
///   * the open lane drifts at most one step at a time, because a two-lane
///     dash inside a reaction window is not a fair ask.
class SpawnDirector {
  SpawnDirector({required int seed}) : _rnd = math.Random(seed);

  final math.Random _rnd;
  final List<Obstacle> obstacles = <Obstacle>[];
  final List<Coin> coins = <Coin>[];

  double _cursor = 30; // z of the next event
  int _nextId = 0;
  int _freeLane = 1;

  void reset() {
    obstacles.clear();
    coins.clear();
    _cursor = 30;
    _nextId = 0;
    _freeLane = 1;
  }

  void update(double runnerZ, double speed, double metres) {
    final reach = runnerZ + Tune.spawnAhead;
    while (_cursor < reach) {
      _emit(_cursor, metres, speed);
      _cursor += Difficulty.gapAt(metres, speed);
    }
    obstacles.removeWhere((o) => o.z + o.length < runnerZ - Tune.recycleBehind);
    coins.removeWhere((c) => c.taken || c.z < runnerZ - Tune.recycleBehind);
  }

  void _emit(double z, double metres, double speed) {
    final free = _pickFreeLane();
    final kind = Difficulty.pickKind(metres, _rnd);

    final others = <int>[0, 1, 2]..remove(free);
    others.shuffle(_rnd);

    var blockCount = 1;
    if (Difficulty.maxBlockedLanes(metres) > 1 && _rnd.nextInt(100) < 42) {
      blockCount = 2;
    }
    for (var i = 0; i < blockCount; i++) {
      obstacles.add(
        Obstacle(
          kind: kind == ObstacleKind.train && i > 0
              ? ObstacleKind.barrierLow
              : kind,
          lane: others[i],
          z: z,
          id: _nextId++,
        ),
      );
    }

    // Coins reward the lane the player should already be in.
    if (_rnd.nextInt(100) < 76) {
      _emitCoins(z + 4.5, free, metres);
    }
  }

  /// Keep the open lane sticky: same lane most of the time, otherwise one step
  /// away — never a jump two lanes across.
  int _pickFreeLane() {
    final roll = _rnd.nextInt(100);
    if (roll < 58) return _freeLane;
    final step = _rnd.nextBool() ? 1 : -1;
    final next = (_freeLane + step).clamp(0, 2);
    _freeLane = next;
    return next;
  }

  void _emitCoins(double z, int lane, double metres) {
    final count = 4 + _rnd.nextInt(3);
    final arch = metres > 120 && _rnd.nextInt(100) < 28;
    for (var i = 0; i < count; i++) {
      final t = count == 1 ? 0.0 : i / (count - 1);
      final y = arch ? 0.65 + math.sin(t * math.pi) * 1.15 : 0.8;
      coins.add(Coin(lane: lane, z: z + i * 1.55, y: y));
    }
  }
}
