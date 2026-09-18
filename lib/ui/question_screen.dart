import 'package:flutter/material.dart';

import '../quiz/quiz_controller.dart';
import 'kiosk_copy.dart';
import 'kiosk_theme.dart';
import 'widgets/option_card.dart';

class QuestionScreen extends StatelessWidget {
  const QuestionScreen({super.key, required this.controller});

  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    final question = controller.currentQuestion;
    if (question == null) {
      return const SizedBox.expand();
    }

    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));
    final progress = (controller.currentIndex + 1) / controller.questionCount;
    final showingAdvance = controller.highlightedOptionIndex != null;

    return Padding(
      padding: metrics.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProgressHeader(
            heading: question.heading,
            total: controller.questionCount,
            percentLabel: '%${controller.progressPercent}',
            progress: progress,
          ),
          SizedBox(height: metrics.sp(18)),
          Text(
            question.prompt,
            key: const Key('question-prompt'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: KioskColors.cream,
              fontSize: metrics.sp(32),
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          SizedBox(height: metrics.sp(22)),
          Expanded(child: _OptionGrid(controller: controller)),
          SizedBox(height: metrics.sp(12)),
          SizedBox(
            height: metrics.sp(28),
            child: AnimatedOpacity(
              opacity: showingAdvance ? 1 : 0,
              duration: const Duration(milliseconds: 160),
              child: Text(
                KioskCopy.advancingHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: KioskColors.cyan.withValues(alpha: 0.85),
                  fontSize: metrics.sp(16),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.heading,
    required this.total,
    required this.percentLabel,
    required this.progress,
  });

  final String heading;
  final int total;
  final String percentLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));

    return Column(
      children: [
        Row(
          children: [
            Text(
              heading,
              key: const Key('question-heading'),
              style: TextStyle(
                color: KioskColors.cyan,
                fontSize: metrics.sp(16),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
              ),
            ),
            Text(
              ' / $total',
              style: TextStyle(
                color: KioskColors.cyan.withValues(alpha: 0.7),
                fontSize: metrics.sp(16),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Text(
              percentLabel,
              style: TextStyle(
                color: KioskColors.cream.withValues(alpha: 0.7),
                fontSize: metrics.sp(16),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: metrics.sp(10)),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: metrics.sp(8),
            backgroundColor: KioskColors.navyMid,
            color: KioskColors.cyan,
          ),
        ),
      ],
    );
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({required this.controller});

  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));
    final question = controller.currentQuestion!;

    Widget cell(int index) {
      return Expanded(
        child: OptionCard(
          key: Key('option-${question.options[index].label}'),
          option: question.options[index],
          selected: controller.highlightedOptionIndex == index,
          enabled: controller.acceptingInput,
          onTap: () => controller.selectOption(index),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cell(0),
              SizedBox(width: metrics.sp(18)),
              cell(1),
            ],
          ),
        ),
        SizedBox(height: metrics.sp(18)),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cell(2),
              SizedBox(width: metrics.sp(18)),
              cell(3),
            ],
          ),
        ),
      ],
    );
  }
}
