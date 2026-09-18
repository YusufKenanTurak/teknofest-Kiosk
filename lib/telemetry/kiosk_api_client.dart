import 'dart:convert';

import 'package:http/http.dart' as http;

import '../app_update/app_version.dart';
import '../config/app_config.dart';
import 'quiz_telemetry.dart';

/// Fire-and-forget client. Network failure never blocks the kiosk.
class KioskApiTelemetry implements QuizTelemetry {
  KioskApiTelemetry({
    required this.baseUrl,
    required this.kioskId,
    required this.applicationVersion,
    http.Client? client,
    this.timeout = const Duration(seconds: 2),
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String kioskId;
  final String applicationVersion;
  final Duration timeout;
  final http.Client _client;

  String? _sessionId;
  String? _sessionToken;
  String? _correlationId;
  Future<void> _chain = Future<void>.value();

  static QuizTelemetry fromConfig({http.Client? client}) {
    final base = AppConfig.normalizeBaseUrl(AppConfig.apiBaseUrl);
    if (base.isEmpty) {
      return const NoopQuizTelemetry();
    }
    return KioskApiTelemetry(
      baseUrl: base,
      kioskId: AppConfig.kioskId,
      applicationVersion: AppVersion.label,
      client: client,
    );
  }

  @override
  void testStarted() {
    _enqueue(_start);
  }

  @override
  void questionAnswered({
    required int questionNumber,
    required String optionCode,
  }) {
    _enqueue(
      () => _post(
        '/api/v1/tests/${_sessionId ?? ''}/answers',
        body: {
          'question_number': questionNumber,
          'option_code': optionCode,
        },
        withToken: true,
      ),
    );
  }

  @override
  void testCompleted() {
    _enqueue(
      () => _post(
        '/api/v1/tests/${_sessionId ?? ''}/complete',
        withToken: true,
      ),
    );
  }

  @override
  void testAbandoned() {
    _enqueue(
      () => _post(
        '/api/v1/tests/${_sessionId ?? ''}/abandon',
        withToken: true,
      ),
    );
  }

  void _enqueue(Future<void> Function() work) {
    _chain = _chain.then((_) => work()).catchError((_) {});
  }

  Future<void> _start() async {
    _sessionId = null;
    _sessionToken = null;
    _correlationId = _newId();
    final uri = Uri.parse('$baseUrl/api/v1/tests');
    final response = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'X-Correlation-ID': _correlationId!,
          },
          body: jsonEncode({
            'kiosk_id': kioskId,
            'application_version': applicationVersion,
          }),
        )
        .timeout(timeout);
    if (response.statusCode != 200) {
      return;
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return;
    }
    _sessionId = decoded['session_id'] as String?;
    _sessionToken = decoded['session_token'] as String?;
  }

  Future<void> _post(
    String path, {
    Map<String, Object?>? body,
    bool withToken = false,
  }) async {
    if (_sessionId == null || _sessionToken == null) {
      return;
    }
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_correlationId != null) 'X-Correlation-ID': _correlationId!,
      if (withToken) 'X-Session-Token': _sessionToken!,
    };
    await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: body == null ? '{}' : jsonEncode(body),
        )
        .timeout(timeout);
  }

  static String _newId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final raw = now.toRadixString(16).padLeft(12, '0');
    return '00000000-0000-4000-a000-${raw.substring(raw.length - 12)}';
  }
}
