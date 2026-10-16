/// Every tunable in one place — no magic numbers anywhere else in the code
/// (docs/TECH_ARCHITECTURE.md §5).
abstract final class Tune {
  // ---- lanes & world units -------------------------------------------------
  static const List<double> laneX = [-1.0, 0.0, 1.0];
  static const double laneGauge = 0.75; // rail gauge inside one lane
  static const double trackHalf = 1.55; // ballast bed half width
  static const double sleeperSpacing = 0.72;
  static const double runnerHeight = 1.78;
  static const double runnerWidth = 0.64;

  // ---- controls ------------------------------------------------------------
  static const double laneChange = 0.14; // seconds for one lane step
  static const double jumpAirtime = 0.62;
  static const double jumpApex = 1.18; // world units above the rail head
  static const double rollDuration = 0.55;
  static const double rollHeight = 0.9; // hitbox height while rolling
  static const double inputBuffer = 0.15; // a swipe survives this long
  static const double swipeThreshold = 24.0; // px before a drag counts

  // ---- speed & difficulty --------------------------------------------------
  static const double speedStart = 11.0; // world units per second
  static const double speedCap = 26.0;
  static const double speedRamp = 0.0094; // units/s gained per metre

  // ---- camera --------------------------------------------------------------
  static const double camHeight = 2.75;
  static const double camDist = 6.1;
  static const double fovDeg = 56.0;
  static const double horizonFraction = 0.42;
  static const double camXLag = 9.0;

  // ---- world streaming -----------------------------------------------------
  static const double viewNear = 0.55; // nearest z the renderer draws
  static const double viewFar = 58.0;
  static const double spawnAhead = 58.0;
  static const double recycleBehind = 9.0;
  static const double sleeperReach = 34.0;

  // ---- fairness ------------------------------------------------------------
  static const double minReact = 0.65; // seconds of guaranteed reaction time
  static const double freeLaneWin = 25.0; // metres of the free-lane law

  // ---- scoring -------------------------------------------------------------
  static const int coinValue = 5;
  static const int styleBonus = 5;
  static const double nearMiss = 0.3;

  // ---- feel ----------------------------------------------------------------
  static const double hitStop = 0.26; // seconds before the death anim
  static const double deathSlowmo = 0.35; // time scale during the death beat
}
