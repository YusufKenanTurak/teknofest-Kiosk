import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import '../domain/app_update_models.dart';
import '../running_app_version.dart';
import 'android_apk_installer.dart';

/// Sunucudaki `version.json` dosyasını okur.
/// Referans: croms_omega_auth `VersionCheckerService`.
class VersionCheckerService {
  VersionCheckerService._internal();

  static final VersionCheckerService _singleton =
      VersionCheckerService._internal();

  factory VersionCheckerService() => _singleton;

  static const Duration checkInterval = Duration(minutes: 5);
  static const Duration requestTimeout = Duration(seconds: 10);
  static const String manifestFileName = 'version.json';

  final ValueNotifier<AppUpdateState> state = ValueNotifier<AppUpdateState>(
    const AppUpdateState.idle(),
  );

  final ValueNotifier<AppUpdateDiagnostics> diagnostics =
      ValueNotifier<AppUpdateDiagnostics>(const AppUpdateDiagnostics());

  Timer? _versionCheckTimer;
  http.Client? _client;
  String? _apiBaseUrl;
  bool _checking = false;
  bool _started = false;

  bool get isStarted => _started;

  AppUpdateChannel get channel {
    if (kIsWeb) return AppUpdateChannel.web;
    return defaultTargetPlatform == TargetPlatform.iOS
        ? AppUpdateChannel.ios
        : AppUpdateChannel.android;
  }

  Future<void> startVersionCheck({
    String? apiBaseUrl,
    http.Client? client,
  }) async {
    _apiBaseUrl = apiBaseUrl ?? _apiBaseUrl;
    _client ??= client ?? http.Client();
    _started = true;

    debugPrint('[UPDATE] Checking update');
    await _checkVersion();

    _versionCheckTimer?.cancel();
    _versionCheckTimer = Timer.periodic(checkInterval, (_) => _checkVersion());
  }

  void updateApiBaseUrl(String? apiBaseUrl) {
    final normalized = apiBaseUrl?.trim();
    if (normalized == null || normalized.isEmpty) return;
    _apiBaseUrl = normalized;
  }

  void stopVersionCheck() {
    _versionCheckTimer?.cancel();
    _versionCheckTimer = null;
  }

  Future<bool> checkNow() async {
    if (!_started) return false;
    await _checkVersion();
    return state.value.updateAvailable;
  }

  Future<void> _checkVersion() async {
    if (_checking) return;
    _checking = true;

    final uri = manifestUri();
    try {
      if (uri == null) {
        _recordFailure(
          uri,
          'Manifest adresi çözülemedi (API adresi boş olabilir)',
        );
        return;
      }

      debugPrint('[UPDATE] Manifest: $uri');
      final manifest = await _fetchManifest(uri);
      if (manifest == null) return;

      final running = await _resolveRunningVersion();
      debugPrint('[UPDATE] Current version: ${running.label}');
      debugPrint('[UPDATE] Server version: ${manifest.label}');

      state.value = AppUpdateState(
        channel: channel,
        manifest: manifest,
        lastCheckedAt: DateTime.now(),
        runningVersion: running,
      );
      diagnostics.value = AppUpdateDiagnostics(
        manifestUrl: uri.toString(),
        lastCheckedAt: DateTime.now(),
        remoteLabel: manifest.label,
      );

      if (manifest.isUpdatePending(running: running)) {
        debugPrint('[UPDATE] Update available');
      } else {
        debugPrint('[UPDATE] No update');
      }
    } catch (e) {
      _recordFailure(uri, e.toString());
      debugPrint('[UPDATE] version kontrolü başarısız — $e');
    } finally {
      _checking = false;
    }
  }

  Future<RunningAppVersion> _resolveRunningVersion() async {
    if (AndroidApkInstaller.isSupported) {
      try {
        final installed = await AndroidApkInstaller.readInstalledVersion();
        if (installed != null) return installed;
      } catch (e) {
        debugPrint('[UPDATE] yüklü sürüm okunamadı — $e');
      }
    }
    return RunningAppVersion.fromEmbedded();
  }

  void _recordFailure(Uri? uri, String error) {
    diagnostics.value = AppUpdateDiagnostics(
      manifestUrl: uri?.toString(),
      lastCheckedAt: DateTime.now(),
      lastError: error,
    );
  }

  Future<AppUpdateManifest?> _fetchManifest(Uri uri) async {
    final client = _client ??= http.Client();
    final response = await client
        .get(
          uri,
          headers: const {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
          },
        )
        .timeout(requestTimeout);

    if (response.statusCode != 200) {
      _recordFailure(uri, 'HTTP ${response.statusCode}');
      return null;
    }

    final body = _jsonBodyOrNull(response, uri);
    if (body == null) return null;

    final manifest = AppUpdateManifest.tryParse(body, channel);
    if (manifest == null) {
      _recordFailure(uri, 'Manifest içinde sürüm alanı yok');
    }
    return manifest;
  }

  @visibleForTesting
  Uri? manifestUri() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final apiBaseUrl = _apiBaseUrl?.trim();
    if (apiBaseUrl == null || apiBaseUrl.isEmpty) return null;

    final normalized = AppConfig.normalizeBaseUrl(apiBaseUrl);
    return Uri.parse('$normalized/app/$manifestFileName?t=$timestamp');
  }

  Map<String, dynamic>? _jsonBodyOrNull(http.Response response, Uri uri) {
    final contentType = response.headers['content-type'] ?? '';
    final body = decodeManifestBody(response.bodyBytes);

    if (!contentType.contains('json') && !body.startsWith('{')) {
      _recordFailure(
        uri,
        '$manifestFileName bulunamadı (JSON yerine HTML döndü)',
      );
      return null;
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      _recordFailure(uri, 'Manifest bir JSON nesnesi değil');
      return null;
    } on FormatException catch (e) {
      _recordFailure(uri, 'Manifest ayrıştırılamadı: ${e.message}');
      return null;
    }
  }

  @visibleForTesting
  static String decodeManifestBody(List<int> bodyBytes) {
    final decoded = utf8.decode(bodyBytes, allowMalformed: true);
    return decoded.startsWith('\uFEFF')
        ? decoded.substring(1).trim()
        : decoded.trim();
  }

  Uri? resolveApkUri(String apkUrl) {
    final trimmed = apkUrl.trim();
    if (trimmed.isEmpty) return null;

    final parsed = Uri.tryParse(trimmed);
    final Uri resolved;
    if (parsed != null && parsed.hasScheme) {
      if (parsed.scheme != 'https') {
        return null;
      }
      resolved = parsed;
    } else {
      final apiBaseUrl = _apiBaseUrl?.trim();
      if (apiBaseUrl == null || apiBaseUrl.isEmpty) return null;
      resolved = Uri.parse(
        '${AppConfig.normalizeBaseUrl(apiBaseUrl)}/app/',
      ).resolve(trimmed);
    }

    return resolved.replace(
      queryParameters: {
        ...resolved.queryParameters,
        't': '${DateTime.now().millisecondsSinceEpoch}',
      },
    );
  }

  @visibleForTesting
  void resetForTest() {
    stopVersionCheck();
    _client = null;
    _apiBaseUrl = null;
    _checking = false;
    _started = false;
    state.value = const AppUpdateState.idle();
    diagnostics.value = const AppUpdateDiagnostics();
  }
}

final versionChecker = VersionCheckerService();
