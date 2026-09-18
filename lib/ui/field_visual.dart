import 'package:flutter/material.dart';

import '../domain/engineering_field.dart';

class FieldVisual {
  const FieldVisual({
    required this.field,
    required this.shortLabel,
    required this.icon,
    required this.accent,
  });

  final EngineeringField field;
  final String shortLabel;
  final IconData icon;
  final Color accent;

  static const Map<EngineeringField, FieldVisual> all = {
    EngineeringField.computer: FieldVisual(
      field: EngineeringField.computer,
      shortLabel: 'Bilgisayar',
      icon: Icons.laptop_mac_rounded,
      accent: Color(0xFF22D3EE),
    ),
    EngineeringField.chemistry: FieldVisual(
      field: EngineeringField.chemistry,
      shortLabel: 'Kimya',
      icon: Icons.science_rounded,
      accent: Color(0xFF34D399),
    ),
    EngineeringField.environment: FieldVisual(
      field: EngineeringField.environment,
      shortLabel: 'Çevre',
      icon: Icons.eco_rounded,
      accent: Color(0xFF4ADE80),
    ),
    EngineeringField.mechanical: FieldVisual(
      field: EngineeringField.mechanical,
      shortLabel: 'Makine',
      icon: Icons.settings_rounded,
      accent: Color(0xFF60A5FA),
    ),
    EngineeringField.electrical: FieldVisual(
      field: EngineeringField.electrical,
      shortLabel: 'Elektrik-Elektronik',
      icon: Icons.bolt_rounded,
      accent: Color(0xFFA78BFA),
    ),
    EngineeringField.industrial: FieldVisual(
      field: EngineeringField.industrial,
      shortLabel: 'Endüstri',
      icon: Icons.bar_chart_rounded,
      accent: Color(0xFFFB923C),
    ),
    EngineeringField.civil: FieldVisual(
      field: EngineeringField.civil,
      shortLabel: 'İnşaat',
      icon: Icons.engineering_rounded,
      accent: Color(0xFFFBBF24),
    ),
  };

  static FieldVisual of(EngineeringField field) => all[field]!;
}
