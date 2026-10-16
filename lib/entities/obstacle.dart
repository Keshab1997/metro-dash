/// Obstacle kinds and their hitbox numbers (docs/GAME_DESIGN.md §5.1).
enum ObstacleKind {
  barrierLow, // railway gate — jump it
  barrierHigh, // hanging banner — roll under it
  train, // parked coach — change lane
  cones, // cone cluster — jump or dodge
}

class Obstacle {
  Obstacle(
      {required this.kind,
      required this.lane,
      required this.z,
      required this.id});

  final ObstacleKind kind;
  final int lane; // lane centre the obstacle blocks
  final double z; // where its near edge is
  final int id;

  /// Set once the runner's z has passed it — used for the near-miss bonus.
  bool passed = false;

  double get height => switch (kind) {
        ObstacleKind.barrierLow => 0.95,
        ObstacleKind.barrierHigh => 2.70,
        ObstacleKind.train => 2.55,
        ObstacleKind.cones => 0.55,
      };

  /// Gap under a hanging banner — a rolling hero fits through it.
  double get gapUnder => kind == ObstacleKind.barrierHigh ? 0.95 : 0;

  double get length => kind == ObstacleKind.train ? 9.5 : 0.85;

  /// The kind's flavour of danger, kept here so the collision rules and the
  /// painter never disagree about geometry.
  bool get mustJump =>
      kind == ObstacleKind.barrierLow || kind == ObstacleKind.cones;

  bool get mustRoll => kind == ObstacleKind.barrierHigh;

  bool get mustDodge => kind == ObstacleKind.train;
}
