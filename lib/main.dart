import 'package:flutter/material.dart';

import 'core/palette.dart';
import 'game/metro_dash_game.dart';

void main() => runApp(const MetroDashApp());

class MetroDashApp extends StatelessWidget {
  const MetroDashApp({super.key});

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
      home: const MetroDashGame(),
    );
  }
}
