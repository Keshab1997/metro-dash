import 'package:flutter/material.dart';

import '../core/palette.dart';
import '../core/strings.dart';
import 'widgets.dart';

/// The world is the backdrop — this panel floats over it.
class TitleScreen extends StatelessWidget {
  const TitleScreen({
    super.key,
    required this.strings,
    required this.best,
    required this.totalCoins,
    required this.onPlay,
    required this.onToggleLang,
  });

  final Strings strings;
  final int best;
  final int totalCoins;
  final VoidCallback onPlay;
  final VoidCallback onToggleLang;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 620;
          return Align(
            alignment: const Alignment(0, 0.42),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Panel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      strings.t('title'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: compact ? 34 : 40,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: Pal.hoodie,
                        shadows: <Shadow>[
                          Shadow(
                            color: Pal.accent.withValues(alpha: 0.55),
                            offset: const Offset(0, 4),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.t('tagline'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Pal.ink.withValues(alpha: 0.62),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: <Widget>[
                        InfoCard(label: strings.t('best'), value: '$best'),
                        InfoCard(
                          label: strings.t('coins'),
                          value: '$totalCoins',
                          accent: Pal.coinDeep,
                          leading: const CoinChip(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    BigButton(
                      label: strings.t('play'),
                      icon: Icons.play_arrow_rounded,
                      onPressed: onPlay,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.t('hint'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Pal.ink.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onToggleLang,
                      child: Text(
                        strings.code == 'bn' ? 'English' : 'বাংলা',
                        style: const TextStyle(
                          color: Pal.hoodie,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
