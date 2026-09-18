import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_update/presentation/app_update_host.dart';
import 'config/app_config.dart';
import 'data/quiz_catalog.dart';
import 'quiz/quiz_controller.dart';
import 'telemetry/kiosk_api_client.dart';
import 'ui/calculating_screen.dart';
import 'ui/kiosk_theme.dart';
import 'ui/question_screen.dart';
import 'ui/result_screen.dart';
import 'ui/start_screen.dart';
import 'ui/timeout_screen.dart';
import 'ui/widgets/brand_marks.dart';
import 'ui/widgets/kiosk_frame.dart';

class TeknofestKioskApp extends StatefulWidget {
  const TeknofestKioskApp({super.key, this.controller});

  /// Injected by widget tests. Production creates its own controller.
  final QuizController? controller;

  @override
  State<TeknofestKioskApp> createState() => _TeknofestKioskAppState();
}

class _TeknofestKioskAppState extends State<TeknofestKioskApp>
    with WidgetsBindingObserver {
  late final QuizController _controller;
  late final bool _ownsController;
  static const _heroAsset = AssetImage('assets/images/kiosk_city_hero.png');
  static const _ministryLogo = AssetImage(MinistryMark.assetPath);
  static const _teknofestLogo = AssetImage(TeknofestMark.assetPath);

  @override
  void initState() {
    super.initState();
    QuizCatalog.validate();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        QuizController(telemetry: KioskApiTelemetry.fromConfig());
    WidgetsBinding.instance.addObserver(this);
    _applyKioskSystemUi();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_heroAsset, context);
    precacheImage(_ministryLogo, context);
    precacheImage(_teknofestLogo, context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyKioskSystemUi();
    }
  }

  void _applyKioskSystemUi() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teknofest Kiosk',
      debugShowCheckedModeBanner: false,
      theme: KioskTheme.theme(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AppUpdateHost(
        resolveApiBaseUrl: () async => AppConfig.updateBaseUrl,
        child: PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {},
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) => _controller.registerInteraction(),
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                return Scaffold(
                  backgroundColor: KioskColors.navyDeep,
                  body: KioskFrame(
                    child: KeyedSubtree(
                      key: ValueKey(
                        '${_controller.phase}-${_controller.currentIndex}',
                      ),
                      child: switch (_controller.phase) {
                        QuizPhase.start => StartScreen(controller: _controller),
                        QuizPhase.question => QuestionScreen(
                          controller: _controller,
                        ),
                        QuizPhase.calculating => const CalculatingScreen(),
                        QuizPhase.result => ResultScreen(
                          controller: _controller,
                        ),
                        QuizPhase.timeout => TimeoutScreen(
                          controller: _controller,
                        ),
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
