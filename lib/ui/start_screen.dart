import 'package:flutter/material.dart';

import '../data/quiz_catalog.dart';
import '../quiz/quiz_controller.dart';
import 'kiosk_copy.dart';
import 'kiosk_theme.dart';
import 'widgets/brand_marks.dart';
import 'widgets/kiosk_buttons.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key, required this.controller});

  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));

    return Padding(
      padding: metrics.screenPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 11,
            child: Padding(
              padding: EdgeInsets.only(right: metrics.sp(28)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MinistryMark(),
                  SizedBox(height: metrics.sp(16)),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            QuizCatalog.startTitle,
                            key: const Key('start-title'),
                            style: TextStyle(
                              color: KioskColors.cream,
                              fontSize: metrics.sp(46),
                              fontWeight: FontWeight.w800,
                              height: 1.12,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: metrics.sp(22)),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: metrics.sp(760),
                            ),
                            child: Text(
                              QuizCatalog.startBody,
                              key: const Key('start-body'),
                              style: TextStyle(
                                color: KioskColors.cream.withValues(alpha: 0.86),
                                fontSize: metrics.sp(22),
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: metrics.sp(16)),
                  GradientButton(
                    key: const Key('start-button'),
                    label: QuizCatalog.startActionLabel,
                    enabled: controller.acceptingInput,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: controller.startTest,
                  ),
                  SizedBox(height: metrics.sp(12)),
                  Text(
                    KioskCopy.startEyebrow,
                    style: TextStyle(
                      color: KioskColors.cyan,
                      fontSize: metrics.sp(14),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(flex: 9, child: const HeroPanel()),
        ],
      ),
    );
  }
}
