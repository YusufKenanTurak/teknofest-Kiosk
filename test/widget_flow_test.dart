import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teknofest_kiosk/app.dart';
import 'package:teknofest_kiosk/app_update/application/version_checker_service.dart';
import 'package:teknofest_kiosk/config/app_config.dart';
import 'package:teknofest_kiosk/config/external_browser.dart';
import 'package:teknofest_kiosk/data/quiz_catalog.dart';
import 'package:teknofest_kiosk/domain/engineering_field.dart';
import 'package:teknofest_kiosk/quiz/quiz_controller.dart';
import 'package:teknofest_kiosk/ui/kiosk_copy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(versionChecker.resetForTest);
  tearDown(versionChecker.resetForTest);

  Future<QuizController> pumpApp(
    WidgetTester tester, {
    Size size = const Size(1920, 1080),
    QuizController? controller,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final quiz =
        controller ??
        QuizController(
          advanceDelay: Duration.zero,
          calculatingDelay: Duration.zero,
          idleTimeout: Duration.zero,
          timeoutDisplayDuration: Duration.zero,
        );
    addTearDown(quiz.dispose);
    await tester.pumpWidget(
      TeknofestKioskApp(key: ObjectKey(quiz), controller: quiz),
    );
    await tester.pump();
    return quiz;
  }

  testWidgets('start screen opens with approved copy and start action', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text(QuizCatalog.startTitle), findsOneWidget);
    expect(find.text(QuizCatalog.startBody), findsOneWidget);
    expect(find.text(KioskCopy.ministryNameStacked), findsOneWidget);
    expect(find.byKey(const Key('start-button')), findsOneWidget);
    expect(find.text(QuizCatalog.startActionLabel), findsOneWidget);
  });

  testWidgets('start begins the test on question 1', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pump();

    expect(find.text('SORU 1'), findsOneWidget);
    expect(find.text(QuizCatalog.questions[0].prompt), findsOneWidget);
    expect(find.text(QuizCatalog.questions[0].options[0].text), findsOneWidget);
    expect(find.text(QuizCatalog.questions[0].options[3].text), findsOneWidget);
  });

  testWidgets('selecting an option advances to the next question', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('option-A')));
    await tester.pump();

    expect(find.text('SORU 2'), findsOneWidget);
    expect(find.text(QuizCatalog.questions[1].prompt), findsOneWidget);
  });

  testWidgets('question 15 leads to the matching result screen', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pump();

    for (var i = 0; i < 15; i++) {
      expect(find.text('SORU ${i + 1}'), findsOneWidget);
      await tester.tap(find.byKey(const Key('option-A')));
      await tester.pump();
    }

    final civil = QuizCatalog.resultFor(EngineeringField.civil);
    expect(find.byKey(const Key('result-title')), findsOneWidget);
    expect(find.text(civil.title), findsOneWidget);
    expect(find.text(civil.description), findsOneWidget);
    expect(find.text(civil.slogan), findsOneWidget);
    expect(find.text(QuizCatalog.restartActionLabel), findsOneWidget);
    expect(find.text(QuizCatalog.discoverTmkActionLabel), findsOneWidget);
  });

  testWidgets('replay starts a clean test at question 1', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pump();

    for (var i = 0; i < 15; i++) {
      await tester.tap(find.byKey(const Key('option-B')));
      await tester.pump();
    }

    expect(find.text('Endüstri Mühendisliği'), findsOneWidget);

    await tester.tap(find.byKey(const Key('restart-button')));
    await tester.pump();

    expect(find.text('SORU 1'), findsOneWidget);
    expect(find.text(QuizCatalog.questions[0].prompt), findsOneWidget);
    expect(find.text('Endüstri Mühendisliği'), findsNothing);
    expect(find.text(QuizCatalog.startTitle), findsNothing);
  });

  testWidgets('TMK button opens the configured site', (tester) async {
    Uri? opened;
    ExternalBrowser.open = (uri) async {
      opened = uri;
      return true;
    };
    addTearDown(() {
      ExternalBrowser.open = ExternalBrowser.openExternal;
    });

    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pump();
    for (var i = 0; i < 15; i++) {
      await tester.tap(find.byKey(const Key('option-B')));
      await tester.pump();
    }

    await tester.tap(find.byKey(const Key('discover-tmk-button')));
    await tester.pump();

    expect(opened, Uri.parse(AppConfig.tmkUrl));
    expect(find.text('Endüstri Mühendisliği'), findsOneWidget);
  });

  testWidgets('rapid taps do not skip questions', (tester) async {
    final controller = QuizController(
      advanceDelay: const Duration(milliseconds: 400),
      calculatingDelay: Duration.zero,
      idleTimeout: Duration.zero,
    );
    await pumpApp(tester, controller: controller);
    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('option-A')));
    await tester.tap(find.byKey(const Key('option-B')));
    await tester.tap(find.byKey(const Key('option-C')));
    await tester.pump();

    expect(controller.currentIndex, 0);
    expect(controller.answers[0], QuizCatalog.questions[0].options[0].field);
    expect(find.text('SORU 1'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();

    expect(controller.currentIndex, 1);
    expect(find.text('SORU 2'), findsOneWidget);
  });

  testWidgets('system back does not leave the kiosk flow', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('SORU 1'), findsOneWidget);
    expect(find.text(QuizCatalog.startTitle), findsNothing);
  });

  testWidgets('landscape kiosk layout shows all four options', (tester) async {
    await pumpApp(tester, size: const Size(1920, 1080));
    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pump();

    expect(find.byKey(const Key('option-A')), findsOneWidget);
    expect(find.byKey(const Key('option-B')), findsOneWidget);
    expect(find.byKey(const Key('option-C')), findsOneWidget);
    expect(find.byKey(const Key('option-D')), findsOneWidget);
  });

  testWidgets('calculating screen appears after question 15', (tester) async {
    final controller = QuizController(
      advanceDelay: Duration.zero,
      calculatingDelay: const Duration(milliseconds: 300),
      idleTimeout: Duration.zero,
    );
    await pumpApp(tester, controller: controller);
    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pump();

    for (var i = 0; i < 15; i++) {
      await tester.tap(find.byKey(const Key('option-A')));
      await tester.pump();
    }

    expect(find.byKey(const Key('calculating-title')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.byKey(const Key('result-title')), findsOneWidget);
    expect(find.text('İnşaat Mühendisliği'), findsOneWidget);
  });

  testWidgets('idle timeout shows timeout copy then returns to start', (
    tester,
  ) async {
    final controller = QuizController(
      advanceDelay: Duration.zero,
      calculatingDelay: Duration.zero,
      idleTimeout: const Duration(milliseconds: 50),
      timeoutDisplayDuration: const Duration(milliseconds: 50),
    );
    await pumpApp(tester, controller: controller);
    await tester.tap(find.byKey(const Key('start-button')));
    await tester.pump();
    expect(find.text('SORU 1'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byKey(const Key('timeout-title')), findsOneWidget);
    expect(find.text(KioskCopy.timeoutTitle), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(QuizCatalog.startTitle), findsOneWidget);
    expect(find.text('SORU 1'), findsNothing);
  });

  testWidgets('result CTAs stay above the kiosk footer on compact screens', (
    tester,
  ) async {
    const sizes = <Size>[
      Size(1920, 1080),
      Size(1366, 768),
      Size(1024, 768),
      Size(844, 390),
      Size(430, 932),
      Size(390, 844),
      Size(375, 667),
      Size(320, 568),
    ];

    for (final size in sizes) {
      final quiz = QuizController(
        advanceDelay: Duration.zero,
        calculatingDelay: Duration.zero,
        idleTimeout: Duration.zero,
        timeoutDisplayDuration: Duration.zero,
      );
      await pumpApp(tester, size: size, controller: quiz);
      expect(
        find.byKey(const Key('start-button')),
        findsOneWidget,
        reason: 'start screen missing at $size',
      );
      await tester.tap(find.byKey(const Key('start-button')));
      await tester.pump();
      for (var i = 0; i < 15; i++) {
        await tester.ensureVisible(find.byKey(const Key('option-A')));
        await tester.tap(find.byKey(const Key('option-A')));
        await tester.pump();
      }

      expect(find.byKey(const Key('discover-tmk-button')), findsOneWidget);
      expect(find.byKey(const Key('kiosk-footer')), findsOneWidget);

      final cta = tester.getRect(find.byKey(const Key('discover-tmk-button')));
      final footer = tester.getRect(find.byKey(const Key('kiosk-footer')));
      expect(
        cta.overlaps(footer),
        isFalse,
        reason: 'CTA overlaps footer at $size',
      );
      expect(
        cta.bottom <= footer.top + 0.5,
        isTrue,
        reason: 'CTA must sit above footer at $size (cta=$cta footer=$footer)',
      );

      final badge = tester.getSize(find.byKey(const Key('ministry-logo-badge')));
      expect(
        badge.width,
        badge.height,
        reason: 'ministry badge must be circular at $size',
      );
    }
  });
}
