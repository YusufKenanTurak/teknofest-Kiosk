import 'package:flutter/material.dart';

import '../domain/engineering_field.dart';
import 'field_visual.dart';
import 'kiosk_copy.dart';
import 'kiosk_theme.dart';

class CalculatingScreen extends StatefulWidget {
  const CalculatingScreen({super.key});

  @override
  State<CalculatingScreen> createState() => _CalculatingScreenState();
}

class _CalculatingScreenState extends State<CalculatingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));

    return Padding(
      padding: metrics.screenPadding,
      child: Column(
        children: [
          const Spacer(),
          Text(
            KioskCopy.calculatingTitle,
            key: const Key('calculating-title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: KioskColors.cream,
              fontSize: metrics.sp(42),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: metrics.sp(12)),
          Text(
            KioskCopy.calculatingSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: KioskColors.cream.withValues(alpha: 0.75),
              fontSize: metrics.sp(20),
            ),
          ),
          SizedBox(height: metrics.sp(48)),
          Row(
            children: [
              for (final field in EngineeringField.values)
                Expanded(child: _FieldOrb(visual: FieldVisual.of(field))),
            ],
          ),
          SizedBox(height: metrics.sp(36)),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: SizedBox(
                  height: metrics.sp(14),
                  width: metrics.sp(760),
                  child: Stack(
                    children: [
                      const ColoredBox(color: Color(0xFF12324F)),
                      FractionallySizedBox(
                        widthFactor: 0.18 + (_controller.value * 0.82),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF22D3EE),
                                Color(0xFFA78BFA),
                                Color(0xFFEC4899),
                                Color(0xFFFBBF24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: metrics.sp(28)),
          Text(
            '${KioskCopy.pillarIdea}  •  ${KioskCopy.pillarTalent}  •  ${KioskCopy.pillarSociety}',
            style: TextStyle(
              color: KioskColors.cream.withValues(alpha: 0.45),
              fontSize: metrics.sp(14),
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _FieldOrb extends StatelessWidget {
  const _FieldOrb({required this.visual});

  final FieldVisual visual;

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));
    return Column(
      children: [
        Container(
          width: metrics.sp(78),
          height: metrics.sp(78),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: visual.accent.withValues(alpha: 0.12),
            border: Border.all(color: visual.accent.withValues(alpha: 0.7)),
          ),
          child: Icon(visual.icon, color: visual.accent, size: metrics.sp(34)),
        ),
        SizedBox(height: metrics.sp(10)),
        Text(
          visual.shortLabel,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: KioskColors.cream.withValues(alpha: 0.8),
            fontSize: metrics.sp(12),
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
      ],
    );
  }
}
