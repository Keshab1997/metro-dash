import 'dart:math' as math;
import 'dart:ui';

import '../core/config.dart';

/// A world point after projection: where it lands on screen and how big a
/// world unit is there.
class Projected {
  const Projected(this.screen, this.scale, this.depth);

  final Offset screen;
  final double scale; // pixels per world unit at this depth
  final double depth; // dz from the camera — the sort key
}

/// The one and only world → screen law (docs/TECH_ARCHITECTURE.md §4).
///
/// Sprites are 2D, but everything lives in a 3D-ish world: x across the three
/// lanes, y up from the rail head, z along the track. Perspective comes from
/// the 1/dz scale law — one function, every entity.
class Projection {
  Projection(this.size);

  Size size;

  late double focal =
      (size.height * 0.5) / math.tan((Tune.fovDeg * math.pi / 180) * 0.5);
  late double horizonY = size.height * Tune.horizonFraction;

  double camX = 0;
  double camY = Tune.camHeight;
  double camZ = -Tune.camDist;

  void resize(Size s) {
    size = s;
    focal = (s.height * 0.5) / math.tan((Tune.fovDeg * math.pi / 180) * 0.5);
    horizonY = s.height * Tune.horizonFraction;
  }

  /// dz of the near clip plane — closer than this we do not draw.
  double get nearZ => camZ + Tune.viewNear;
  double get farZ => camZ + Tune.viewFar;

  Projected project(double x, double y, double z) {
    final dz = (z - camZ).clamp(Tune.viewNear, 400.0);
    final s = focal / dz;
    return Projected(
      Offset(size.width * 0.5 + (x - camX) * s, horizonY - (y - camY) * s),
      s,
      dz,
    );
  }

  /// Perspective-correct quad on a horizontal plane (y constant) between two
  /// z values. Used for everything lying on the ground: ballast, sleepers,
  /// grass banks, rail shine.
  Path groundQuad(double x0, double x1, double zNear, double zFar, double y) {
    final a = project(x0, y, zNear);
    final b = project(x1, y, zNear);
    final c = project(x1, y, zFar);
    final d = project(x0, y, zFar);
    return Path()
      ..moveTo(a.screen.dx, a.screen.dy)
      ..lineTo(b.screen.dx, b.screen.dy)
      ..lineTo(c.screen.dx, c.screen.dy)
      ..lineTo(d.screen.dx, d.screen.dy)
      ..close();
  }

  /// A billboard quad standing on the ground: vertical plane at a fixed z,
  /// spanning x0..x1 and yBottom..yTop. Used for facades, gates, trains.
  Path uprightQuad(
      double x0, double x1, double z, double yBottom, double yTop) {
    final bl = project(x0, yBottom, z);
    final br = project(x1, yBottom, z);
    final tr = project(x1, yTop, z);
    final tl = project(x0, yTop, z);
    return Path()
      ..moveTo(bl.screen.dx, bl.screen.dy)
      ..lineTo(br.screen.dx, br.screen.dy)
      ..lineTo(tr.screen.dx, tr.screen.dy)
      ..lineTo(tl.screen.dx, tl.screen.dy)
      ..close();
  }

  /// A vertical strip at a fixed x, spanning zNear..zFar and yBottom..yTop.
  /// Used for the parapet walls and every long side surface.
  Path wallQuad(
      double x, double zNear, double zFar, double yBottom, double yTop) {
    final bl = project(x, yBottom, zNear);
    final br = project(x, yBottom, zFar);
    final tr = project(x, yTop, zFar);
    final tl = project(x, yTop, zNear);
    return Path()
      ..moveTo(bl.screen.dx, bl.screen.dy)
      ..lineTo(br.screen.dx, br.screen.dy)
      ..lineTo(tr.screen.dx, tr.screen.dy)
      ..lineTo(tl.screen.dx, tl.screen.dy)
      ..close();
  }

  /// Haze/fade for the far end of the world: 1 = fully visible.
  double fadeAt(double z, {double start = 34, double end = Tune.viewFar}) {
    final dz = z - camZ;
    if (dz <= start) return 1;
    return (1 - (dz - start) / (end - start)).clamp(0.0, 1.0);
  }
}
