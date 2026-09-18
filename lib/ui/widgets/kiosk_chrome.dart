import 'package:flutter/material.dart';

import '../kiosk_copy.dart';
import '../kiosk_theme.dart';

class KioskHeader extends StatelessWidget {
  const KioskHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        metrics.sp(36),
        metrics.sp(10),
        metrics.sp(36),
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              KioskCopy.headerSlogan,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: KioskColors.cream.withValues(alpha: 0.78),
                fontSize: metrics.sp(16),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                _Pillar(
                  label: KioskCopy.pillarIdea,
                  icon: Icons.lightbulb_outline,
                ),
                SizedBox(width: metrics.sp(18)),
                _Pillar(
                  label: KioskCopy.pillarTalent,
                  icon: Icons.auto_awesome,
                ),
                SizedBox(width: metrics.sp(18)),
                _Pillar(
                  label: KioskCopy.pillarSociety,
                  icon: Icons.groups_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KioskFooter extends StatelessWidget {
  const KioskFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));

    return ColoredBox(
      color: KioskColors.navyDeep,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: KioskColors.cyan.withValues(alpha: 0.18),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              metrics.sp(36),
              metrics.sp(12),
              metrics.sp(36),
              metrics.sp(12),
            ),
            child: Row(
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Flexible(
                        child: _FooterIcon(
                          icon: Icons.lightbulb_outline,
                          label: KioskCopy.pillarIdea,
                        ),
                      ),
                      SizedBox(width: metrics.sp(16)),
                      Flexible(
                        child: _FooterIcon(
                          icon: Icons.auto_awesome,
                          label: KioskCopy.pillarTalent,
                        ),
                      ),
                      SizedBox(width: metrics.sp(16)),
                      Flexible(
                        child: _FooterIcon(
                          icon: Icons.groups_outlined,
                          label: KioskCopy.pillarSociety,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: metrics.sp(16)),
                Flexible(
                  child: Text(
                    KioskCopy.footerTagline,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: KioskColors.cream.withValues(alpha: 0.55),
                      fontSize: metrics.sp(13),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pillar extends StatelessWidget {
  const _Pillar({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));
    return Row(
      children: [
        Icon(icon, size: metrics.sp(16), color: KioskColors.cyan),
        SizedBox(width: metrics.sp(6)),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: KioskColors.cream.withValues(alpha: 0.72),
            fontSize: metrics.sp(12),
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

class _FooterIcon extends StatelessWidget {
  const _FooterIcon({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));
    return Row(
      children: [
        Icon(
          icon,
          size: metrics.sp(18),
          color: KioskColors.cyan.withValues(alpha: 0.9),
        ),
        SizedBox(width: metrics.sp(6)),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: KioskColors.cream.withValues(alpha: 0.7),
              fontSize: metrics.sp(14),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
