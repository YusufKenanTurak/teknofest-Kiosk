import 'package:flutter/material.dart';

import '../config/external_browser.dart';
import '../data/quiz_catalog.dart';
import '../quiz/quiz_controller.dart';
import 'field_visual.dart';
import 'kiosk_copy.dart';
import 'kiosk_theme.dart';
import 'widgets/brand_marks.dart';
import 'widgets/kiosk_buttons.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.controller});

  final QuizController controller;

  @override
  Widget build(BuildContext context) {
    final content = controller.resultContent;
    if (content == null) {
      return const SizedBox.expand();
    }

    final metrics = KioskMetrics.of(MediaQuery.sizeOf(context));
    final visual = FieldVisual.of(content.field);
    final showEmoji = _hasVisibleEmoji(content.emoji);

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
                            KioskCopy.resultEyebrow,
                            style: TextStyle(
                              color: KioskColors.cyan,
                              fontSize: metrics.sp(14),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                            ),
                          ),
                          SizedBox(height: metrics.sp(16)),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: metrics.sp(88),
                                height: metrics.sp(88),
                                decoration: BoxDecoration(
                                  color: visual.accent.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(
                                    metrics.sp(22),
                                  ),
                                  border: Border.all(
                                    color: visual.accent.withValues(alpha: 0.7),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: showEmoji
                                    ? Text(
                                        content.emoji,
                                        key: const Key('result-emoji'),
                                        style: TextStyle(
                                          fontSize: metrics.sp(40),
                                        ),
                                      )
                                    : Icon(
                                        visual.icon,
                                        key: const Key('result-emoji'),
                                        color: visual.accent,
                                        size: metrics.sp(42),
                                      ),
                              ),
                              SizedBox(width: metrics.sp(18)),
                              Expanded(
                                child: Text(
                                  content.title,
                                  key: const Key('result-title'),
                                  style: TextStyle(
                                    color: KioskColors.cream,
                                    fontSize: metrics.sp(40),
                                    fontWeight: FontWeight.w800,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: metrics.sp(20)),
                          Text(
                            content.description,
                            key: const Key('result-description'),
                            style: TextStyle(
                              color: KioskColors.cream.withValues(alpha: 0.86),
                              fontSize: metrics.sp(20),
                              height: 1.45,
                            ),
                          ),
                          SizedBox(height: metrics.sp(18)),
                          Text(
                            content.slogan,
                            key: const Key('result-slogan'),
                            style: TextStyle(
                              color: visual.accent,
                              fontSize: metrics.sp(22),
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: metrics.sp(16)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: OutlineActionButton(
                          key: const Key('discover-tmk-button'),
                          label: QuizCatalog.discoverTmkActionLabel,
                          icon: Icons.open_in_new_rounded,
                          enabled: controller.acceptingInput,
                          expanded: true,
                          onPressed: () {
                            ExternalBrowser.openTmkSite();
                          },
                        ),
                      ),
                      SizedBox(width: metrics.sp(16)),
                      Flexible(
                        child: GradientButton(
                          key: const Key('restart-button'),
                          label: QuizCatalog.restartActionLabel,
                          icon: Icons.refresh_rounded,
                          enabled: controller.acceptingInput,
                          expanded: true,
                          onPressed: controller.replay,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 9,
            child: HeroPanel(
              overlay: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.all(metrics.sp(24)),
                  child: Icon(
                    visual.icon,
                    size: metrics.sp(72),
                    color: Colors.white.withValues(alpha: 0.28),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

bool _hasVisibleEmoji(String emoji) {
  final visible = emoji.replaceAll(RegExp(r'[\uFE0E\uFE0F\u200D\s]'), '');
  return visible.isNotEmpty;
}
