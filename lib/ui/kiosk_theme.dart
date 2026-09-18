import 'package:flutter/material.dart';

class KioskColors {
  const KioskColors._();

  static const Color navyDeep = Color(0xFF05111F);
  static const Color navy = Color(0xFF0A1E36);
  static const Color navyMid = Color(0xFF12324F);
  static const Color panel = Color(0xFF0D2744);
  static const Color panelAlt = Color(0xFF102C4D);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color cyanDeep = Color(0xFF0891B2);
  static const Color magenta = Color(0xFFD946EF);
  static const Color pink = Color(0xFFEC4899);
  static const Color gold = Color(0xFFE0B34A);
  static const Color cream = Color(0xFFF4F7FB);
  static const Color ink = Color(0xFF102033);
  static const Color glassBorder = Color(0x557DD3F0);
}

class KioskTheme {
  const KioskTheme._();

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: KioskColors.cyan,
        brightness: Brightness.dark,
        primary: KioskColors.cyan,
        surface: KioskColors.navy,
      ),
      scaffoldBackgroundColor: KioskColors.navyDeep,
      fontFamily: 'Roboto',
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: KioskColors.cream,
        displayColor: KioskColors.cream,
      ),
    );
  }
}

class KioskMetrics {
  KioskMetrics._(this.size, this.scale);

  factory KioskMetrics.of(Size size) {
    final widthScale = size.width / 1920;
    final heightScale = size.height / 1080;
    final scale = (widthScale < heightScale ? widthScale : heightScale).clamp(
      0.62,
      1.35,
    );
    return KioskMetrics._(size, scale);
  }

  final Size size;
  final double scale;

  bool get isLandscape => size.width >= size.height;

  double sp(double value) => value * scale;

  EdgeInsets get screenPadding =>
      EdgeInsets.fromLTRB(sp(36), sp(12), sp(36), sp(10));
}
