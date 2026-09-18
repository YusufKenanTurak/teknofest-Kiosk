import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'app_update/application/version_checker_service.dart';
import 'config/app_config.dart';
import 'data/quiz_catalog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SemanticsBinding.instance.ensureSemantics();
  QuizCatalog.validate();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  unawaited(
    versionChecker.startVersionCheck(apiBaseUrl: AppConfig.updateBaseUrl),
  );

  runApp(const TeknofestKioskApp());
}
