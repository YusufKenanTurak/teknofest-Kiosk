import 'package:flutter/material.dart';

import '../quiz/quiz_controller.dart';
import 'kiosk_copy.dart';
import 'kiosk_theme.dart';
import 'widgets/kiosk_buttons.dart';

class TimeoutScreen extends StatelessWidget {
  const TimeoutScreen({super.key, required this.controller});

  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));
    final remaining = controller.continueRemainingSeconds;
    final urgent = remaining > 0 && remaining <= 3;
    final ringColor = urgent ? KioskColors.magenta : KioskColors.cyan;

    return Padding(
      padding: metrics.screenPadding,
      child: Column(
        children: [
          Text(
            KioskCopy.timeoutTitle,
            key: const Key('timeout-title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: KioskColors.cream,
              fontSize: metrics.sp(30),
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          SizedBox(height: metrics.sp(10)),
          Text(
            KioskCopy.timeoutBody,
            key: const Key('timeout-body'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: KioskColors.cream.withValues(alpha: 0.78),
              fontSize: metrics.sp(20),
              height: 1.35,
            ),
          ),
          Expanded(
            child: Center(
              child: _ContinueCountdown(
                key: const Key('timeout-seconds'),
                seconds: remaining,
                ringColor: ringColor,
                size: metrics.sp(180),
                fontSize: metrics.sp(64),
              ),
            ),
          ),
          GradientButton(
            key: const Key('continue-test-button'),
            label: KioskCopy.continueTestAction,
            enabled: controller.canActOnContinuePrompt,
            onPressed: controller.continueTest,
          ),
          SizedBox(height: metrics.sp(28)),
          KioskTextAction(
            key: const Key('return-home-action'),
            label: KioskCopy.returnHomeAction,
            enabled: controller.canActOnContinuePrompt,
            onPressed: controller.restart,
          ),
          SizedBox(height: metrics.sp(8)),
        ],
      ),
    );
  }
}

class _ContinueCountdown extends StatelessWidget {
  const _ContinueCountdown({
    super.key,
    required this.seconds,
    required this.ringColor,
    required this.size,
    required this.fontSize,
  });

  final int seconds;
  final Color ringColor;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: 4),
        boxShadow: [
          BoxShadow(color: ringColor.withValues(alpha: 0.25), blurRadius: 24),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Text(
          '$seconds',
          key: ValueKey(seconds),
          style: TextStyle(
            color: KioskColors.cream,
            fontSize: fontSize,
            fontWeight: FontWeight.w300,
            height: 1,
          ),
        ),
      ),
    );
  }
}
