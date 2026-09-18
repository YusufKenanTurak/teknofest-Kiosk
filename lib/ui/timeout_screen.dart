import 'package:flutter/material.dart';

import '../quiz/quiz_controller.dart';
import 'kiosk_copy.dart';
import 'kiosk_theme.dart';

class TimeoutScreen extends StatelessWidget {
  const TimeoutScreen({super.key, required this.controller});

  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: controller.restart,
      child: Padding(
        padding: metrics.screenPadding,
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: metrics.sp(180),
              height: metrics.sp(180),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: KioskColors.cyan, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: KioskColors.cyan.withValues(alpha: 0.25),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Text(
                '${KioskCopy.idleTimeoutSeconds}',
                key: const Key('timeout-seconds'),
                style: TextStyle(
                  color: KioskColors.cream,
                  fontSize: metrics.sp(64),
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
            SizedBox(height: metrics.sp(28)),
            Text(
              KioskCopy.timeoutTitle,
              key: const Key('timeout-title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KioskColors.cream,
                fontSize: metrics.sp(28),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: metrics.sp(10)),
            Text(
              KioskCopy.timeoutBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: KioskColors.cream.withValues(alpha: 0.75),
                fontSize: metrics.sp(20),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
