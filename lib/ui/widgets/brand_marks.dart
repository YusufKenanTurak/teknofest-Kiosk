import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../kiosk_copy.dart';
import '../kiosk_theme.dart';

class MinistryMark extends StatelessWidget {
  const MinistryMark({super.key});

  static const assetPath = 'assets/images/logo_bakanlik.png';

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));
    final logoSize = metrics.sp(120);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _WhiteLogoPlate(
          assetPath: assetPath,
          semanticsLabel: KioskCopy.ministryName,
          height: logoSize,
          width: logoSize,
          circular: true,
        ),
        SizedBox(width: metrics.sp(16)),
        Text(
          KioskCopy.ministryNameStacked,
          style: TextStyle(
            color: KioskColors.cream,
            fontSize: metrics.sp(20),
            fontWeight: FontWeight.w700,
            height: 1.22,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }
}

class TeknofestMark extends StatelessWidget {
  const TeknofestMark({super.key});

  static const assetPath = 'assets/images/logo_teknofest.png';

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));
    return _WhiteLogoPlate(
      assetPath: assetPath,
      semanticsLabel: 'TEKNOFEST',
      height: metrics.sp(148),
      width: metrics.sp(268),
    );
  }
}

class _WhiteLogoPlate extends StatelessWidget {
  const _WhiteLogoPlate({
    required this.assetPath,
    required this.semanticsLabel,
    required this.height,
    required this.width,
    this.circular = false,
  });

  final String assetPath;
  final String semanticsLabel;
  final double height;
  final double width;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final pad = metrics.sp(circular ? 7 : 10);
    final innerW = math.max(1.0, width - pad * 2);
    final innerH = math.max(1.0, height - pad * 2);
    final decodeScale = math.max(dpr, 2.0);
    final cacheW = (innerW * decodeScale).round().clamp(64, 2048);

    return Semantics(
      image: true,
      label: semanticsLabel,
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.all(pad),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: circular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circular ? null : BorderRadius.circular(metrics.sp(16)),
        ),
        child: Image.asset(
          assetPath,
          width: innerW,
          height: innerH,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          isAntiAlias: true,
          gaplessPlayback: true,
          cacheWidth: cacheW,
        ),
      ),
    );
  }
}

class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key, this.overlay});

  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));

    return ClipRRect(
      borderRadius: BorderRadius.circular(metrics.sp(28)),
      child: ColoredBox(
        color: const Color(0xFF0B1C30),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Image(
              image: AssetImage('assets/images/kiosk_city_hero.png'),
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              gaplessPlayback: true,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    KioskColors.navyDeep.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              top: metrics.sp(18),
              right: metrics.sp(18),
              child: const TeknofestMark(),
            ),
            ?overlay,
          ],
        ),
      ),
    );
  }
}
