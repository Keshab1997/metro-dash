import 'package:flutter/material.dart';

import '../core/palette.dart';
import '../core/strings.dart';
import 'widgets.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.strings,
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  final Strings strings;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Pal.ink.withValues(alpha: 0.45),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Panel(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    strings.t('paused'),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Pal.ink,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  BigButton(
                    label: strings.t('resume'),
                    icon: Icons.play_arrow_rounded,
                    onPressed: onResume,
                  ),
                  const SizedBox(height: 10),
                  BigButton(
                    label: strings.t('restart'),
                    icon: Icons.refresh_rounded,
                    color: Pal.hoodie,
                    onPressed: onRestart,
                  ),
                  const SizedBox(height: 10),
                  BigButton(
                    label: strings.t('quit'),
                    icon: Icons.home_rounded,
                    color: Pal.railDark,
                    onPressed: onQuit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
