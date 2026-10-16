import 'package:flutter/material.dart';

import '../core/palette.dart';
import '../core/strings.dart';
import 'widgets.dart';

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({
    super.key,
    required this.strings,
    required this.score,
    required this.best,
    required this.coins,
    required this.newBest,
    required this.onRetry,
    required this.onMenu,
  });

  final Strings strings;
  final int score;
  final int best;
  final int coins;
  final bool newBest;
  final VoidCallback onRetry;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
          child: Panel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 6,
                  children: <Widget>[
                    Text(
                      strings.t('gameOver'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Pal.ink,
                      ),
                    ),
                    if (newBest)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Pal.coin,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          strings.t('newBest'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Pal.ink,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: <Widget>[
                    InfoCard(label: strings.t('score'), value: '$score'),
                    InfoCard(label: strings.t('best'), value: '$best'),
                    InfoCard(
                      label: strings.t('coins'),
                      value: '$coins',
                      accent: Pal.coinDeep,
                      leading: const CoinChip(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                BigButton(
                  label: strings.t('retry'),
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onMenu,
                  child: Text(
                    strings.t('menu'),
                    style: const TextStyle(
                      color: Pal.hoodie,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
