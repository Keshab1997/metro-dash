import 'package:flutter/material.dart';

import 'core/assets.dart';
import 'core/palette.dart';
import 'game/metro_dash_game.dart';

void main() => runApp(const MetroDashApp());

class MetroDashApp extends StatelessWidget {
  const MetroDashApp({super.key, this.preloadedAssets});

  /// Sprites passed in by a caller that already decoded them (tests, or a warm
  /// start). Null means "load them in the background", which is what the app
  /// does in production.
  final GameAssets? preloadedAssets;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metro Dash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Pal.ink,
        fontFamily: 'Rubik',
      ),
      home: MetroDashGame(preloadedAssets: preloadedAssets),
    );
  }
}
