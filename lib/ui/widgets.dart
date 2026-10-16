import 'package:flutter/material.dart';

import '../core/palette.dart';

/// One big, thumb-friendly pill button.
class BigButton extends StatefulWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = Pal.accent,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color color;

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 90),
        child: Container(
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(30),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Pal.ink.withValues(alpha: 0.28),
                blurRadius: _down ? 6 : 14,
                offset: Offset(0, _down ? 2 : 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.icon != null) ...<Widget>[
                Icon(widget.icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tiny drawn coin. Emoji glyphs are not guaranteed on every platform, so
/// the coin is a widget, not a character.
class CoinChip extends StatelessWidget {
  const CoinChip({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Pal.coin,
        shape: BoxShape.circle,
        border: Border.all(color: Pal.coinDeep, width: size * 0.16),
      ),
    );
  }
}

/// Small translucent card used by the HUD.
class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.label,
    required this.value,
    this.accent,
    this.leading,
  });

  final String label;
  final String value;
  final Color? accent;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Pal.paper.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Pal.ink.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: Pal.ink.withValues(alpha: 0.55),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (leading != null) ...<Widget>[
                leading!,
                const SizedBox(width: 5)
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  color: accent ?? Pal.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Round icon button (pause, sound).
class IconPill extends StatelessWidget {
  const IconPill(
      {super.key, required this.icon, required this.onTap, this.semanticLabel});

  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Pal.paper.withValues(alpha: 0.92),
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Pal.ink.withValues(alpha: 0.16),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Pal.ink, size: 22),
        ),
      ),
    );
  }
}

/// Cream panel with a soft shadow — the shared look of every overlay.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        color: Pal.paper.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Pal.ink.withValues(alpha: 0.30),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
