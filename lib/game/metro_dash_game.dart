import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/assets.dart';
import '../core/config.dart';
import '../core/palette.dart';
import '../core/strings.dart';
import '../entities/obstacle.dart';
import '../entities/runner.dart';
import '../render/game_painter.dart';
import '../render/particles.dart';
import '../services/save_service.dart';
import '../systems/collision.dart';
import '../systems/difficulty.dart';
import '../systems/input_controller.dart';
import '../systems/scoring.dart';
import '../systems/spawn_director.dart';
import '../ui/game_over_screen.dart';
import '../ui/hud.dart';
import '../ui/pause_overlay.dart';
import '../ui/title_screen.dart';
import '../world/environment.dart';
import '../world/skyline.dart';
import '../world/track_builder.dart';
import 'camera_rig.dart';
import 'projection.dart';
import 'run_state.dart';

/// The whole game: one ticker, one world, one screen. Owned by the captain
/// (docs/TECH_ARCHITECTURE.md §2).
class MetroDashGame extends StatefulWidget {
  const MetroDashGame({super.key});

  @override
  State<MetroDashGame> createState() => _MetroDashGameState();
}

class _MetroDashGameState extends State<MetroDashGame>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const int _spawnSeed = 20261017;

  late final Ticker _ticker;
  final SaveService _save = SaveService();
  final InputController _input = InputController();
  final Runner _runner = Runner();
  final Scoring _scoring = Scoring();
  final CameraRig _camera = CameraRig();
  final Skyline _skyline = Skyline();
  final TrackBuilder _track = TrackBuilder();
  final Environment _environment = Environment();
  final Particles _particles = Particles();
  late final SpawnDirector _director = SpawnDirector(seed: _spawnSeed);

  GameAssets? _assets;
  Projection? _projection;

  RunState _state = RunState.title;
  Strings _strings = const Strings('en');

  Duration _last = Duration.zero;
  double _elapsed = 0;
  double _countdown = 0;
  double _speed = Tune.speedStart;
  double _shake = 0;
  double _flash = 0;
  double _deathT = 0;
  double _deathScale = 1;

  Offset _dragStart = Offset.zero;
  Offset _dragPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker(_tick)..start();
    _boot();
  }

  Future<void> _boot() async {
    await _save.load();
    if (!mounted) return;
    setState(() {
      _strings = Strings(_save.lang);
      _scoring.best = _save.best;
    });
    final assets = await GameAssets.load();
    if (!mounted || assets == null) return;
    setState(() => _assets = assets);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _state == RunState.running) {
      setState(() => _state = RunState.paused);
    }
  }

  // ---- the loop ------------------------------------------------------------
  void _tick(Duration now) {
    if (_last == Duration.zero) {
      _last = now;
      return;
    }
    final dt = ((now - _last).inMicroseconds / 1000000).clamp(0.0, 0.05);
    _last = now;
    _elapsed += dt;
    _skyline.update(dt);

    switch (_state) {
      case RunState.countdown:
        _countdown -= dt;
        _particles.update(dt);
        if (_countdown <= 0) _state = RunState.running;
      case RunState.running:
        _step(dt);
      case RunState.title:
      case RunState.gameOver:
      case RunState.loading:
      case RunState.paused:
        _particles.update(dt);
    }

    if (mounted) setState(() {});
  }

  void _step(double dt) {
    final dying = !_runner.alive;
    final step = dying ? dt * _deathScale : dt;
    final speed = dying ? _speed : Difficulty.speedAt(_runner.z);
    _speed = speed;
    final metres = _runner.z;

    if (!dying) {
      _input.apply(_runner, _elapsed);
    }
    _runner.update(step, speed);

    if (dying) {
      _deathT -= dt;
      _deathScale = (_deathScale - dt * 0.55).clamp(0.06, 0.5);
      if (_deathT <= 0) {
        _state = RunState.gameOver;
        _save.recordRun(score: _scoring.score, coins: _scoring.coins);
        _particles.clear();
      }
    } else {
      _director.update(_runner.z, speed, metres);

      final hit = CollisionSystem.hit(_runner, _director.obstacles);
      if (hit != null) {
        _crash(hit);
      } else {
        for (final coin in CollisionSystem.pickup(_runner, _director.coins)) {
          _scoring.addCoin();
          _particles.sparkle(Tune.laneX[coin.lane], coin.y, coin.z);
          _particles.popup('+${Tune.coinValue}', Tune.laneX[coin.lane],
              coin.y + 0.3, coin.z);
        }
        final nearMisses =
            CollisionSystem.collectNearMisses(_runner, _director.obstacles);
        if (nearMisses > 0) {
          _scoring.addStyle();
          _flash = math.max(_flash, 0.22);
          _particles.popup('+${Tune.styleBonus}', _runner.x, _runner.y + 1.5,
              _runner.z + 1.2);
        }
      }
      _scoring.update(step, metres);
    }

    _camera.follow(runnerX: _runner.x, runnerZ: _runner.z, dt: dt);
    _camera.updateDip(dt);
    _environment.update(_runner.z);
    _particles.update(dt);
    _shake = (_shake - dt * 2.4).clamp(0.0, 1.0);
    _flash = (_flash - dt * 2.6).clamp(0.0, 1.0);
  }

  void _crash(Obstacle hit) {
    _runner.die();
    _scoring.finish();
    _shake = 1;
    _flash = 0.85;
    _deathT = 0.8;
    _deathScale = 0.5;
    _camera.bump(0.4);
    _particles.dust(_runner.x, 0.5, _runner.z, n: 16, spread: 0.9, size: 0.3);
  }

  // ---- state changes -------------------------------------------------------
  void _startRun() {
    setState(() {
      _runner.reset();
      _scoring.resetRun();
      _scoring.best = math.max(_scoring.best, _save.best);
      _director.reset();
      _environment.reset();
      _particles.clear();
      _camera.reset();
      _input.clear();
      _speed = Tune.speedStart;
      _shake = 0;
      _flash = 0;
      _deathScale = 1;
      _countdown = 3.0;
      _state = RunState.countdown;
    });
  }

  void _toTitle() {
    setState(() {
      _runner.reset();
      _scoring.resetRun();
      _director.reset();
      _environment.reset();
      _particles.clear();
      _camera.reset();
      _state = RunState.title;
    });
  }

  void _togglePause() {
    if (_state == RunState.running) {
      setState(() => _state = RunState.paused);
    } else if (_state == RunState.paused) {
      setState(() => _state = RunState.running);
    }
  }

  void _toggleLang() {
    final next = _strings.code == 'bn' ? 'en' : 'bn';
    _save.setLang(next);
    setState(() => _strings = Strings(next));
  }

  // ---- input ---------------------------------------------------------------
  void _handleDrag(LaneIntent intent) {
    if (_state == RunState.running) _input.queue(intent, _elapsed);
  }

  void _onTap() {
    switch (_state) {
      case RunState.title:
        _startRun();
      case RunState.gameOver:
        _startRun();
      case RunState.running:
        _handleDrag(LaneIntent.jump);
      case RunState.countdown:
      case RunState.paused:
      case RunState.loading:
        break;
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP) {
      _togglePause();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_state == RunState.title || _state == RunState.gameOver) _startRun();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _handleDrag(LaneIntent.left);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      _handleDrag(LaneIntent.right);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.keyW ||
        key == LogicalKeyboardKey.space) {
      _handleDrag(LaneIntent.jump);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      _handleDrag(LaneIntent.roll);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ---- build ---------------------------------------------------------------
  String get _countdownLabel {
    if (_countdown <= 0.45) return 'GO';
    return '${_countdown.ceil()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Pal.ink,
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final projection = _projection ??= Projection(size);
          if (projection.size != size) projection.resize(size);
          projection
            ..camX = _camera.x
            ..camY = _camera.y - _camera.dip
            ..camZ = _camera.z;

          final view = FrameView(
            size: size,
            projection: projection,
            assets: _assets,
            skyline: _skyline,
            track: _track,
            environment: _environment,
            runner: _runner,
            obstacles: _director.obstacles,
            coins: _director.coins,
            particles: _particles,
            time: _elapsed,
            speed: _speed,
            shake: _shake,
            flash: _flash,
          );

          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: Focus(
                  autofocus: true,
                  onKeyEvent: _onKey,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onTap,
                    onPanStart: (DragStartDetails d) {
                      _dragStart = d.localPosition;
                      _dragPos = d.localPosition;
                    },
                    onPanUpdate: (DragUpdateDetails d) =>
                        _dragPos = d.localPosition,
                    onPanEnd: (DragEndDetails _) {
                      final intent =
                          InputController.fromDrag(_dragPos - _dragStart);
                      if (intent != null) _handleDrag(intent);
                    },
                    child: Semantics(
                      label: 'Metro Dash running lane runner',
                      child: CustomPaint(
                        painter: GamePainter(view),
                        size: size,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
              if (_state != RunState.title && _state != RunState.loading)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: _state == RunState.gameOver,
                    child: Hud(
                      strings: _strings,
                      score: _scoring.score,
                      best: _scoring.best,
                      coins: _scoring.coins,
                      multiplier: _scoring.multiplierActive ? 2 : 1,
                      multiplierFraction: _scoring.multiplierTime / 10,
                      onPause: _togglePause,
                    ),
                  ),
                ),
              if (_state == RunState.countdown)
                Center(
                  child: Text(
                    _countdownLabel,
                    style: TextStyle(
                      fontSize: 96,
                      fontWeight: FontWeight.w900,
                      color: Pal.paper,
                      shadows: <Shadow>[
                        Shadow(
                          color: Pal.ink.withValues(alpha: 0.45),
                          offset: const Offset(0, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                  ),
                ),
              if (_state == RunState.title)
                Positioned.fill(
                  child: TitleScreen(
                    strings: _strings,
                    best: _scoring.best,
                    totalCoins: _save.totalCoins,
                    onPlay: _startRun,
                    onToggleLang: _toggleLang,
                  ),
                ),
              if (_state == RunState.paused)
                Positioned.fill(
                  child: PauseOverlay(
                    strings: _strings,
                    onResume: _togglePause,
                    onRestart: _startRun,
                    onQuit: _toTitle,
                  ),
                ),
              if (_state == RunState.gameOver)
                Positioned.fill(
                  child: GameOverScreen(
                    strings: _strings,
                    score: _scoring.score,
                    best: _scoring.best,
                    coins: _scoring.coins,
                    newBest: _scoring.newBest,
                    onRetry: _startRun,
                    onMenu: _toTitle,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
