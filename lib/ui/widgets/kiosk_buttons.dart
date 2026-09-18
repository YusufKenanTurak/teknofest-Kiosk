import 'package:flutter/material.dart';

import '../kiosk_theme.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));
    final child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(metrics.sp(18)),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(metrics.sp(18)),
            gradient: enabled
                ? const LinearGradient(
                    colors: [Color(0xFF22D3EE), Color(0xFFD946EF)],
                  )
                : null,
            color: enabled ? null : KioskColors.navyMid,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: KioskColors.magenta.withValues(alpha: 0.28),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: metrics.sp(28),
              vertical: metrics.sp(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: enabled
                          ? Colors.white
                          : KioskColors.cream.withValues(alpha: 0.45),
                      fontSize: metrics.sp(22),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                if (icon != null) ...[
                  SizedBox(width: metrics.sp(10)),
                  Icon(icon, color: Colors.white, size: metrics.sp(22)),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (expanded) {
      return SizedBox(height: metrics.sp(64), child: child);
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: metrics.sp(64),
        minWidth: metrics.sp(260),
      ),
      child: child,
    );
  }
}

class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));

    final button = OutlinedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: icon == null
          ? const SizedBox.shrink()
          : Icon(icon, size: metrics.sp(22)),
      label: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: KioskColors.cream,
        side: BorderSide(
          color: KioskColors.cyan.withValues(alpha: 0.7),
          width: 1.6,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: metrics.sp(24),
          vertical: metrics.sp(16),
        ),
        textStyle: TextStyle(
          fontSize: metrics.sp(18),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(metrics.sp(18)),
        ),
      ),
    );

    if (expanded) {
      return SizedBox(
        height: metrics.sp(72),
        width: double.infinity,
        child: button,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: metrics.sp(64),
        minWidth: metrics.sp(260),
      ),
      child: button,
    );
  }
}
