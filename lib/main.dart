import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

void main() => runApp(const DogRoadRunnerApp());

class DogRoadRunnerApp extends StatelessWidget {
  const DogRoadRunnerApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Dog Road Runner',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, fontFamily: 'Trebuchet MS'),
    home: const RunnerScreen(),
  );
}

enum RunState { title, running, gameOver }

class RunnerScreen extends StatefulWidget {
  const RunnerScreen({super.key});
  @override
  State<RunnerScreen> createState() => _RunnerScreenState();
}

class _RunnerScreenState extends State<RunnerScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  RunState _state = RunState.title;
  double _elapsed = 0;
  double _distance = 0;
  double _jumpTime = 10;
  double _speed = 250;
  int _score = 0;
  int _best = 0;
  final List<double> _obstacles = <double>[];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration now) {
    if (_last == Duration.zero) {
      _last = now;
      return;
    }
    final dt = ((now - _last).inMicroseconds / 1000000).clamp(0.0, .05);
    _last = now;
    if (_state != RunState.running) {
      setState(() => _elapsed += dt);
      return;
    }
    _elapsed += dt;
    _distance += dt * _speed;
    _speed = math.min(430, 250 + _distance / 90);
    if (_jumpTime < 10) _jumpTime += dt;
    final nextSpawn = 500 + ((_distance / 620).floor() * 620);
    if (_obstacles.isEmpty || _obstacles.last < nextSpawn) {
      _obstacles.add(nextSpawn.toDouble());
    }
    _obstacles.removeWhere((x) => _distance - x > 1000);
    final dogX = _distance + 190;
    for (final obstacle in _obstacles) {
      final gap = (obstacle - dogX).abs();
      if (gap < 34 && _jumpHeight < 48) {
        _endGame();
        break;
      }
    }
    _score = (_distance / 12).floor();
    setState(() {});
  }

  double get _jumpHeight {
    if (_jumpTime >= .72) return 0;
    return math.sin((_jumpTime / .72) * math.pi) * 112;
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.space ||
            event.logicalKey == LogicalKeyboardKey.arrowUp)) {
      _tap();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _tap() {
    if (_state == RunState.title) {
      setState(() {
        _state = RunState.running;
        _distance = 0;
        _score = 0;
        _speed = 250;
        _jumpTime = 10;
        _obstacles.clear();
      });
    } else if (_state == RunState.gameOver) {
      setState(() {
        _state = RunState.running;
        _distance = 0;
        _score = 0;
        _speed = 250;
        _jumpTime = 10;
        _obstacles.clear();
      });
    } else if (_jumpTime >= .55) {
      setState(() => _jumpTime = 0);
    }
  }

  void _endGame() {
    if (_state != RunState.running) return;
    _best = math.max(_best, _score);
    _state = RunState.gameOver;
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > constraints.maxHeight * .72;
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xff80d8d4), Color(0xffffd8a0), Color(0xfff8b68e)],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? constraints.maxHeight * .62 : 620,
                maxHeight: constraints.maxHeight,
              ),
              child: AspectRatio(
                aspectRatio: isWide
                    ? .62
                    : constraints.maxWidth / constraints.maxHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isWide ? 28 : 0),
                  child: Focus(
                    autofocus: true,
                    onKeyEvent: _handleKey,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _tap,
                      onVerticalDragEnd: (_) => _tap(),
                      child: Semantics(
                        label: _state == RunState.title
                            ? 'Puppy Dash. Tap to play, then tap to jump.'
                            : _state == RunState.gameOver
                            ? 'Game over. Tap to play again.'
                            : 'Puppy Dash running. Tap to jump.',
                        child: CustomPaint(
                          painter: RunnerPainter(
                            time: _elapsed,
                            distance: _distance,
                            score: _score,
                            best: _best,
                            jumpHeight: _jumpHeight,
                            obstacles: List<double>.unmodifiable(_obstacles),
                            state: _state,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class RunnerPainter extends CustomPainter {
  RunnerPainter({
    required this.time,
    required this.distance,
    required this.score,
    required this.best,
    required this.jumpHeight,
    required this.obstacles,
    required this.state,
  });
  final double time, distance, jumpHeight;
  final int score, best;
  final List<double> obstacles;
  final RunState state;

  final Paint _p = Paint()..isAntiAlias = true;
  void fill(Canvas c, Color color) {
    _p.color = color;
    _p.style = PaintingStyle.fill;
    _p.shader = null;
  }

  void stroke(Canvas c, Color color, double width) {
    _p.color = color;
    _p.style = PaintingStyle.stroke;
    _p.strokeWidth = width;
    _p.shader = null;
  }

  void oval(Canvas c, Rect r, Color color) {
    fill(c, color);
    c.drawOval(r, _p);
  }

  void round(Canvas c, Rect r, double radius, Color color) {
    fill(c, color);
    c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)), _p);
  }

  void circle(Canvas c, Offset o, double r, Color color) {
    fill(c, color);
    c.drawCircle(o, r, _p);
  }

  void line(Canvas c, Offset a, Offset b, Color color, double width) {
    stroke(c, color, width);
    c.drawLine(a, b, _p);
  }

  void text(
    Canvas c,
    String value,
    Offset at,
    double size,
    Color color, {
    bool bold = false,
    TextAlign align = TextAlign.center,
    Color? shadow,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontSize: size,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          color: color,
          height: 1.1,
          shadows: shadow == null
              ? null
              : [
                  Shadow(
                    color: shadow,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();
    tp.paint(c, Offset(at.dx - tp.width / 2, at.dy));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    _p.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xff62cbd0), Color(0xffffe6b2), Color(0xffffbd83)],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, _p);
    _p.shader = null;
    _drawCloud(canvas, w * .22, h * .15, .85);
    _drawCloud(canvas, w * .82, h * .22, .58);
    _drawHills(canvas, size);
    _drawHouses(canvas, size);
    _drawRoad(canvas, size);
    _drawFlowers(canvas, size);
    _drawObstacles(canvas, size);
    _drawDog(canvas, size);
    _drawHud(canvas, size);
    if (state != RunState.running) _drawOverlay(canvas, size);
  }

  void _drawCloud(Canvas c, double x, double y, double s) {
    final drift = math.sin(time * .12 + x) * 8;
    final col = const Color(0xfffff6dd).withValues(alpha: .88);
    oval(
      c,
      Rect.fromCenter(
        center: Offset(x + drift, y),
        width: 70 * s,
        height: 24 * s,
      ),
      col,
    );
    circle(c, Offset(x - 18 * s + drift, y - 4 * s), 15 * s, col);
    circle(c, Offset(x + 2 * s + drift, y - 11 * s), 20 * s, col);
    circle(c, Offset(x + 22 * s + drift, y - 3 * s), 14 * s, col);
  }

  void _drawHills(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final path = Path()
      ..moveTo(0, h * .42)
      ..quadraticBezierTo(w * .18, h * .34, w * .36, h * .43)
      ..quadraticBezierTo(w * .62, h * .34, w, h * .41)
      ..lineTo(w, h * .63)
      ..lineTo(0, h * .63)
      ..close();
    fill(c, const Color(0xff8fbd72));
    c.drawPath(path, _p);
    final path2 = Path()
      ..moveTo(0, h * .49)
      ..quadraticBezierTo(w * .2, h * .42, w * .43, h * .5)
      ..quadraticBezierTo(w * .73, h * .41, w, h * .48)
      ..lineTo(w, h * .64)
      ..lineTo(0, h * .64)
      ..close();
    fill(c, const Color(0xffacd184));
    c.drawPath(path2, _p);
  }

  void _drawHouse(
    Canvas c,
    double x,
    double y,
    double scale,
    Color wall,
    Color roof,
  ) {
    final wallRect = Rect.fromLTWH(x, y, 58 * scale, 64 * scale);
    round(c, wallRect, 3 * scale, wall);
    final roofPath = Path()
      ..moveTo(x - 7 * scale, y + 5 * scale)
      ..lineTo(x + 29 * scale, y - 23 * scale)
      ..lineTo(x + 67 * scale, y + 5 * scale)
      ..close();
    fill(c, roof);
    c.drawPath(roofPath, _p);
    round(
      c,
      Rect.fromLTWH(x + 8 * scale, y + 23 * scale, 14 * scale, 18 * scale),
      2 * scale,
      const Color(0xffffe6a1),
    );
    round(
      c,
      Rect.fromLTWH(x + 37 * scale, y + 22 * scale, 13 * scale, 16 * scale),
      2 * scale,
      const Color(0xffffe6a1),
    );
    round(
      c,
      Rect.fromLTWH(x + 25 * scale, y + 41 * scale, 15 * scale, 23 * scale),
      3 * scale,
      const Color(0xff986751),
    );
  }

  void _drawHouses(Canvas c, Size s) {
    final w = s.width, h = s.height;
    for (int i = 0; i < 3; i++) {
      final shift = (distance * .10) % (w * .72);
      final x = ((i * w * .62 - shift) % (w * 1.86)) - w * .34;
      final y = h * (.40 + i * .018);
      final scale = .78 + i * .17;
      _drawHouse(
        c,
        x,
        y,
        scale,
        i.isEven ? const Color(0xfff8c985) : const Color(0xffa9d6cc),
        i.isEven ? const Color(0xffc56757) : const Color(0xff5d7894),
      );
    }
    for (int i = 0; i < 5; i++) {
      final x =
          ((i * w * .32 - (distance * .20) % (w * .32)) % (w * 1.28)) - w * .1;
      final y = h * .43 + (i % 2) * h * .02;
      circle(c, Offset(x, y), w * .055, const Color(0xff57966d));
      circle(c, Offset(x - 5, y + 7), w * .038, const Color(0xff73a968));
      round(
        c,
        Rect.fromLTWH(x - 2, y + 8, w * .012, h * .07),
        3,
        const Color(0xff9a7251),
      );
    }
  }

  void _drawRoad(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final road = Path()
      ..moveTo(w * .39, h * .49)
      ..lineTo(w * .61, h * .49)
      ..lineTo(w * 1.08, h)
      ..lineTo(-w * .08, h)
      ..close();
    fill(c, const Color(0xffb78565));
    c.drawPath(road, _p);
    final asphalt = Path()
      ..moveTo(w * .42, h * .50)
      ..lineTo(w * .58, h * .50)
      ..lineTo(w * .96, h)
      ..lineTo(w * .04, h)
      ..close();
    fill(c, const Color(0xff686d69));
    c.drawPath(asphalt, _p);
    final edge = Path()
      ..moveTo(w * .405, h * .50)
      ..lineTo(w * .416, h * .50)
      ..lineTo(w * .07, h)
      ..lineTo(w * .03, h)
      ..close();
    fill(c, const Color(0xffffedc4));
    c.drawPath(edge, _p);
    final edge2 = Path()
      ..moveTo(w * .584, h * .50)
      ..lineTo(w * .596, h * .50)
      ..lineTo(w * .97, h)
      ..lineTo(w * .93, h)
      ..close();
    fill(c, const Color(0xffffedc4));
    c.drawPath(edge2, _p);
    for (int i = 0; i < 5; i++) {
      final t = (i / 5 + (distance * .00042) % 1);
      final y = h * (.51 + t * .55);
      final x = w * .5;
      final dashH = h * (.013 + t * .048);
      final dashW = w * (.008 + t * .028);
      round(
        c,
        Rect.fromCenter(center: Offset(x, y), width: dashW, height: dashH),
        dashW,
        const Color(0xffffefc9),
      );
    }
  }

  void _drawFlowers(Canvas c, Size s) {
    final w = s.width, h = s.height;
    for (int i = 0; i < 21; i++) {
      final t = (i / 21 + (distance * .00028) % 1);
      final y = h * (.51 + t * .50);
      final spread = w * (.18 + t * .34);
      final x =
          (i.isEven ? w * .5 - spread : w * .5 + spread) +
          math.sin(i * 4.0) * w * .018;
      if (x < 0 || x > w) continue;
      final r = w * (.003 + t * .008);
      circle(c, Offset(x, y), r * 1.55, const Color(0xff548b55));
      circle(c, Offset(x, y - r * 2), r, const Color(0xffffe788));
      circle(c, Offset(x - r, y - r * 2), r * .7, const Color(0xffff8d79));
    }
  }

  void _drawObstacles(Canvas c, Size s) {
    final w = s.width, h = s.height;
    for (final worldX in obstacles) {
      final ahead = worldX - distance;
      if (ahead < -40 || ahead > 950) continue;
      final t = (ahead / 950).clamp(0.0, 1.0);
      final x = w * .5 + (ahead - 190) * w * .00052;
      final y = h * (.91 - t * .39);
      final side = w * (.025 + t * .035), height = side * .92;
      oval(
        c,
        Rect.fromCenter(
          center: Offset(x, y + height * .43),
          width: side * 1.8,
          height: side * .45,
        ),
        const Color(0x55000000),
      );
      final box = Path()
        ..moveTo(x - side / 2, y - height / 2)
        ..lineTo(x + side / 2, y - height / 2)
        ..lineTo(x + side / 2, y + height / 2)
        ..lineTo(x - side / 2, y + height / 2)
        ..close();
      fill(c, const Color(0xffce8153));
      c.drawPath(box, _p);
      stroke(c, const Color(0xff8c563f), 1.5);
      c.drawPath(box, _p);
      line(
        c,
        Offset(x - side * .48, y - height * .1),
        Offset(x + side * .48, y - height * .1),
        const Color(0xffffd292),
        2,
      );
    }
  }

  void _drawDog(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final bob = state == RunState.running
        ? math.sin(time * 17) * 4
        : math.sin(time * 2) * 2;
    final x = w * .5, y = h * .78 - jumpHeight;
    final scale = w / 390;
    oval(
      c,
      Rect.fromCenter(
        center: Offset(x, h * .80),
        width: 100 * scale,
        height: 23 * scale,
      ),
      const Color(0x440d312b),
    );
    canvasSave(c, x, y + bob, scale);
    // tail, body, ears, face and paws create a friendly original pup.
    stroke(c, const Color(0xffa85137), 9);
    c.drawArc(Rect.fromLTWH(-48, -35, 36, 46), .2, 2.3, false, _p);
    oval(
      c,
      Rect.fromCenter(center: const Offset(0, 0), width: 83, height: 69),
      const Color(0xffd9894d),
    );
    oval(
      c,
      Rect.fromCenter(center: const Offset(8, 6), width: 51, height: 44),
      const Color(0xffffedcf),
    );
    oval(c, Rect.fromLTWH(-34, -57, 25, 43), const Color(0xffa9573c));
    oval(c, Rect.fromLTWH(15, -60, 24, 42), const Color(0xffa9573c));
    oval(c, Rect.fromLTWH(-30, -69, 66, 61), const Color(0xfff1b875));
    oval(c, Rect.fromLTWH(-25, -39, 56, 34), const Color(0xfffff0d8));
    circle(c, const Offset(-10, -48), 4.5, const Color(0xff382f35));
    circle(c, const Offset(15, -48), 4.5, const Color(0xff382f35));
    oval(
      c,
      Rect.fromCenter(center: const Offset(3, -34), width: 14, height: 9),
      const Color(0xff3c3035),
    );
    stroke(c, const Color(0xffa95052), 2);
    c.drawArc(Rect.fromLTWH(-3, -32, 18, 13), .05, 2.8, false, _p);
    final stride = state == RunState.running ? math.sin(time * 17) * 10.0 : 0.0;
    round(
      c,
      Rect.fromLTWH(-26, 22 + stride, 15, 24),
      7,
      const Color(0xfff3d4a3),
    );
    round(
      c,
      Rect.fromLTWH(12, 20 - stride, 15, 26),
      7,
      const Color(0xfff3d4a3),
    );
    circle(c, Offset(-27, 44 + stride), 6, const Color(0xffa9573c));
    circle(c, Offset(25, 44 - stride), 6, const Color(0xffa9573c));
    canvasRestore(c);
  }

  void canvasSave(Canvas c, double x, double y, double scale) {
    c.save();
    c.translate(x, y);
    c.scale(scale);
  }

  void canvasRestore(Canvas c) => c.restore();

  void _drawHud(Canvas c, Size s) {
    final w = s.width;
    round(
      c,
      Rect.fromLTWH(w * .07, s.height * .045, w * .38, s.height * .065),
      24,
      const Color(0xddfff8e9),
    );
    text(
      c,
      '⭐  $score',
      Offset(w * .26, s.height * .058),
      w * .052,
      const Color(0xff74503f),
      bold: true,
    );
    round(
      c,
      Rect.fromLTWH(w * .66, s.height * .045, w * .27, s.height * .065),
      24,
      const Color(0xccfff8e9),
    );
    text(
      c,
      'BEST  $best',
      Offset(w * .795, s.height * .062),
      w * .033,
      const Color(0xff80634b),
      bold: true,
    );
  }

  void _drawOverlay(Canvas c, Size s) {
    final w = s.width, h = s.height;
    fill(c, const Color(0x332b3c3a));
    c.drawRect(Offset.zero & s, _p);
    round(
      c,
      Rect.fromLTWH(w * .09, h * .28, w * .82, h * .36),
      28,
      const Color(0xfffff8e8),
    );
    text(
      c,
      state == RunState.title ? 'PUPPY DASH' : 'NICE RUN!',
      Offset(w * .5, h * .315),
      w * .092,
      const Color(0xff8b5945),
      bold: true,
    );
    if (state == RunState.title) {
      text(
        c,
        'A sunny little adventure',
        Offset(w * .5, h * .395),
        w * .041,
        const Color(0xff82906b),
      );
      _drawMiniDog(c, Offset(w * .5, h * .49), w * .65);
      round(
        c,
        Rect.fromLTWH(w * .22, h * .535, w * .56, h * .075),
        22,
        const Color(0xffef8d55),
      );
      text(
        c,
        'TAP TO PLAY',
        Offset(w * .5, h * .552),
        w * .048,
        Colors.white,
        bold: true,
      );
      text(
        c,
        'Tap anywhere to jump over the crates',
        Offset(w * .5, h * .625),
        w * .031,
        const Color(0xff8c7860),
      );
    } else {
      text(
        c,
        'Score  $score     •     Best  $best',
        Offset(w * .5, h * .405),
        w * .044,
        const Color(0xff82906b),
        bold: true,
      );
      _drawMiniDog(c, Offset(w * .5, h * .50), w * .58);
      round(
        c,
        Rect.fromLTWH(w * .22, h * .535, w * .56, h * .075),
        22,
        const Color(0xffef8d55),
      );
      text(
        c,
        'PLAY AGAIN',
        Offset(w * .5, h * .552),
        w * .046,
        Colors.white,
        bold: true,
      );
      text(
        c,
        'Tap anywhere to try again',
        Offset(w * .5, h * .625),
        w * .031,
        const Color(0xff8c7860),
      );
    }
  }

  void _drawMiniDog(Canvas c, Offset center, double scale) {
    final s = scale / 220;
    canvasSave(c, center.dx, center.dy, s);
    oval(
      c,
      Rect.fromCenter(center: const Offset(0, 5), width: 82, height: 62),
      const Color(0xffd9894d),
    );
    oval(c, Rect.fromLTWH(-27, -53, 22, 39), const Color(0xffa9573c));
    oval(c, Rect.fromLTWH(10, -53, 22, 39), const Color(0xffa9573c));
    oval(c, Rect.fromLTWH(-31, -64, 66, 61), const Color(0xfff1b875));
    oval(c, Rect.fromLTWH(-26, -34, 56, 29), const Color(0xfffff0d8));
    circle(c, const Offset(-11, -43), 4, const Color(0xff382f35));
    circle(c, const Offset(13, -43), 4, const Color(0xff382f35));
    oval(
      c,
      Rect.fromCenter(center: const Offset(1, -30), width: 13, height: 9),
      const Color(0xff3c3035),
    );
    canvasRestore(c);
  }

  @override
  bool shouldRepaint(covariant RunnerPainter old) => true;
}
