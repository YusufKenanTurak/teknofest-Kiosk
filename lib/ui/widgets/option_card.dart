import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../kiosk_theme.dart';

class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final AnswerOption option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));
    final border = selected ? KioskColors.cyan : KioskColors.glassBorder;
    final fill = selected ? const Color(0xFF134E5A) : const Color(0xD90C2746);

    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: '${option.label}. ${option.text}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(metrics.sp(26)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: metrics.sp(22),
              vertical: metrics.sp(18),
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(metrics.sp(26)),
              border: Border.all(color: border, width: selected ? 2.4 : 1.2),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: KioskColors.cyan.withValues(alpha: 0.28),
                        blurRadius: 22,
                        spreadRadius: 1,
                      ),
                    ]
                  : const [],
            ),
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Container(
                    width: metrics.sp(64),
                    height: metrics.sp(64),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: selected
                            ? const [KioskColors.cyan, Color(0xFF38BDF8)]
                            : const [Color(0xFF155E75), Color(0xFF0E7490)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: KioskColors.cyan.withValues(alpha: 0.28),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Text(
                      option.label,
                      style: TextStyle(
                        color: selected
                            ? KioskColors.navyDeep
                            : KioskColors.cream,
                        fontSize: metrics.sp(26),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(width: metrics.sp(18)),
                  Expanded(
                    child: Text(
                      option.text,
                      style: TextStyle(
                        color: KioskColors.cream,
                        fontSize: metrics.sp(22),
                        fontWeight: FontWeight.w600,
                        height: 1.28,
                      ),
                    ),
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
