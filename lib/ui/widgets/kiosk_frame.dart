import 'package:flutter/material.dart';

import '../kiosk_theme.dart';
import 'kiosk_chrome.dart';

class KioskFrame extends StatelessWidget {
  const KioskFrame({super.key, required this.child, this.showChrome = true});

  final Widget child;
  final bool showChrome;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF071627), Color(0xFF0A2340), Color(0xFF06111F)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: IgnorePointer(child: _AmbientGlow())),
          SafeArea(
            child: showChrome
                ? Column(
                    children: [
                      const KioskHeader(),
                      Expanded(
                        child: ClipRect(
                          child: child,
                        ),
                      ),
                      const KioskFooter(key: Key('kiosk-footer')),
                    ],
                  )
                : child,
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.85, -0.9),
              radius: 1.05,
              colors: [
                KioskColors.cyan.withValues(alpha: 0.16),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.95, 0.85),
              radius: 1.1,
              colors: [
                KioskColors.magenta.withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
