/// A collectible coin. Spawned in patterns by the SpawnDirector, drawn as a
/// spinning disc until real coin sprites land (worker C, Batch 1).
class Coin {
  Coin({required this.lane, required this.z, this.y = 0.8});

  final int lane;
  final double z;
  final double y; // height above the rail head — arches follow the jump arc
  bool taken = false;
  double spin = 0;
}
