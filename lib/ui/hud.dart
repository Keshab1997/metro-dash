import 'package:flutter/material.dart';

import '../core/palette.dart';
import '../core/strings.dart';
import 'widgets.dart';

/// Score, coins, the multiplier bar and the pause button.
class Hud extends StatelessWidget {
  const Hud({
    super.key,
    required this.strings,
    required this.score,
    required this.best,
    required this.coins,
    required this.multiplier,
    required this.multiplierFraction,
    required this.onPause,
  });

  final Strings strings;
  final int score;
  final int best;
  final int coins;
  final int multiplier;
  final double multiplierFraction;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                InfoCard(
                  label: strings.t('score'),
                  value: '$score',
                ),
                const SizedBox(width: 8),
                InfoCard(
                  label: strings.t('coins'),
                  value: '$coins',
                  accent: Pal.coinDeep,
                  leading: const CoinChip(),
                ),
                const Spacer(),
                IconPill(
                  icon: Icons.pause_rounded,
                  onTap: onPause,
                  semanticLabel: strings.t('paused'),
                ),
              ],
            ),
            if (multiplier > 1) ...<Widget>[
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Pal.paper.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Pal.ink.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '×$multiplier',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Pal.accent,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 74,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: multiplierFraction.clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: Pal.concrete,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(Pal.accent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
