import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../game/projection.dart';

/// Perspective-correct texture mapping for the pseudo-3D world.
///
/// A flat `ImageShader` on a screen-space path pastes the texture at one
/// fixed size, which is the single biggest "this is not a real place" tell.
/// Here the surface is cut into depth rows and each row carries texture
/// coordinates proportional to **world** x/z, so stones shrink with distance
/// exactly the way the rails do. `Canvas.drawVertices` does the rest.
class TexturedSurface {
  const TexturedSurface._();

  static const int _rows = 30;

  static Float32List _positions(int count) => Float32List(count * 2);
  static Int32List _colors(int count, Color color) =>
      Int32List.fromList(List<int>.filled(count, color.toARGB32()));

  /// A horizontal band of ground between `x0..x1`, at height `y`.
  ///
  /// [pxPerUnit] is how many texture pixels one world unit covers — pick it
  /// from the real-world size the texture represents (a 512 px gravel tile
  /// showing ~2 m of ground is ~256 px per unit).
  static void groundBand(
    Canvas canvas,
    Projection p,
    ui.Image texture, {
    required double x0,
    required double x1,
    required double y,
    required double pxPerUnit,
    double nearDz = 0.45,
    double farDz = 58,
    Color tint = const Color(0xFFFFFFFF),
  }) {
    final n = _rows;
    final positions = _positions((n + 1) * 2);
    final uvs = Float32List((n + 1) * 2 * 2);
    final indices = Uint16List(n * 6);
    for (var i = 0; i <= n; i++) {
      // depth rows spaced geometrically: even on screen, correct in world
      final t = i / n;
      final dz = nearDz * math.pow(farDz / nearDz, t).toDouble();
      final z = p.camZ + dz;
      final a = p.project(x0, y, z).screen;
      final b = p.project(x1, y, z).screen;
      final k = i * 2;
      positions[k * 2] = a.dx;
      positions[k * 2 + 1] = a.dy;
      positions[k * 2 + 2] = b.dx;
      positions[k * 2 + 3] = b.dy;
      uvs[k * 2] = x0 * pxPerUnit;
      uvs[k * 2 + 1] = z * pxPerUnit;
      uvs[k * 2 + 2] = x1 * pxPerUnit;
      uvs[k * 2 + 3] = z * pxPerUnit;
    }
    for (var i = 0; i < n; i++) {
      final k = i * 2;
      final o = i * 6;
      indices[o] = k;
      indices[o + 1] = k + 1;
      indices[o + 2] = k + 2;
      indices[o + 3] = k + 1;
      indices[o + 4] = k + 3;
      indices[o + 5] = k + 2;
    }
    _draw(canvas, texture, positions, uvs, indices, tint, (n + 1) * 2);
  }

  /// A vertical band at a constant `x` — parapets, platform walls, kerbs.
  static void wallBand(
    Canvas canvas,
    Projection p,
    ui.Image texture, {
    required double x,
    required double yBottom,
    required double yTop,
    required double pxPerUnit,
    double nearDz = 0.45,
    double farDz = 40,
    Color tint = const Color(0xFFFFFFFF),
  }) {
    final n = _rows;
    final positions = _positions((n + 1) * 2);
    final uvs = Float32List((n + 1) * 2 * 2);
    final indices = Uint16List(n * 6);
    for (var i = 0; i <= n; i++) {
      final t = i / n;
      final dz = nearDz * math.pow(farDz / nearDz, t).toDouble();
      final z = p.camZ + dz;
      final a = p.project(x, yBottom, z).screen;
      final b = p.project(x, yTop, z).screen;
      final k = i * 2;
      positions[k * 2] = a.dx;
      positions[k * 2 + 1] = a.dy;
      positions[k * 2 + 2] = b.dx;
      positions[k * 2 + 3] = b.dy;
      // u runs up the wall, v runs along the track
      uvs[k * 2] = yBottom * pxPerUnit;
      uvs[k * 2 + 1] = z * pxPerUnit;
      uvs[k * 2 + 2] = yTop * pxPerUnit;
      uvs[k * 2 + 3] = z * pxPerUnit;
    }
    for (var i = 0; i < n; i++) {
      final k = i * 2;
      final o = i * 6;
      indices[o] = k;
      indices[o + 1] = k + 1;
      indices[o + 2] = k + 2;
      indices[o + 3] = k + 1;
      indices[o + 4] = k + 3;
      indices[o + 5] = k + 2;
    }
    _draw(canvas, texture, positions, uvs, indices, tint, (n + 1) * 2);
  }

  static void _draw(
    Canvas canvas,
    ui.Image texture,
    Float32List positions,
    Float32List uvs,
    Uint16List indices,
    Color tint,
    int vertexCount,
  ) {
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: uvs,
      colors: _colors(vertexCount, tint),
      indices: indices,
    );
    canvas.drawVertices(
      vertices,
      BlendMode.modulate,
      Paint()
        ..shader = ui.ImageShader(
          texture,
          TileMode.repeated,
          TileMode.repeated,
          Matrix4.identity().storage,
          filterQuality: FilterQuality.medium,
        ),
    );
  }
}
