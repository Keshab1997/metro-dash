import '../core/config.dart';

/// Score maths, isolated from the loop so a test can prove it.
class Scoring {
  int best = 0;
  int coins = 0;
  int style = 0;
  int score = 0;
  bool newBest = false;

  double _acc = 0; // distance accrued, multiplier applied
  double _lastMetres = 0;

  double multiplier = 1; // 1 or 2 (the ×2 powerup)
  double multiplierTime = 0;

  void resetRun() {
    coins = 0;
    style = 0;
    score = 0;
    _acc = 0;
    _lastMetres = 0;
    multiplier = 1;
    multiplierTime = 0;
    newBest = false;
  }

  bool get multiplierActive => multiplier > 1 && multiplierTime > 0;

  void update(double dt, double metres) {
    if (multiplierActive) multiplierTime = (multiplierTime - dt).clamp(0.0, 99);
    final delta = metres - _lastMetres;
    _lastMetres = metres;
    _acc += delta * multiplier;
    score = _acc.floor() + coins * Tune.coinValue + style;
  }

  void addCoin() => coins++;

  void addStyle() => style += Tune.styleBonus;

  void grantMultiplier([double seconds = 10]) {
    multiplier = 2;
    multiplierTime = seconds;
  }

  /// Called once, the moment a run ends. Returns true when a new record fell.
  bool finish() {
    if (score > best) {
      best = score;
      newBest = true;
    }
    return newBest;
  }
}
