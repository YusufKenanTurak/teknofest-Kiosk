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

    final button = OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: KioskColors.cream,
        side: BorderSide(
          color: KioskColors.cyan.withValues(alpha: 0.7),
          width: 1.6,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: metrics.sp(20),
          vertical: metrics.sp(14),
        ),
        minimumSize: Size(0, metrics.sp(64)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: TextStyle(
          fontSize: metrics.sp(16),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          height: 1.25,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(metrics.sp(18)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: metrics.sp(20)),
            SizedBox(width: metrics.sp(8)),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (expanded) {
      return SizedBox(width: double.infinity, child: button);
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

class KioskTextAction extends StatelessWidget {
  const KioskTextAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));
    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: KioskColors.cream.withValues(alpha: 0.62),
        disabledForegroundColor: KioskColors.cream.withValues(alpha: 0.28),
        padding: EdgeInsets.symmetric(
          horizontal: metrics.sp(12),
          vertical: metrics.sp(6),
        ),
        minimumSize: Size(metrics.sp(44), metrics.sp(28)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        textStyle: TextStyle(
          fontSize: metrics.sp(15),
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          decoration: TextDecoration.underline,
          decorationColor: KioskColors.cream.withValues(alpha: 0.4),
        ),
      ),
      child: Text(label),
    );
  }
}
