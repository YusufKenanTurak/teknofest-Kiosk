import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:teknofest_kiosk/app_update/application/version_checker_service.dart';
import 'package:teknofest_kiosk/app_update/domain/app_update_models.dart';
import 'package:teknofest_kiosk/app_update/running_app_version.dart';
import 'package:teknofest_kiosk/config/app_config.dart';

const _apiBaseUrl = 'https://testapp.limak.com.tr/teknofest';

http.Client _clientReturning(
  String body, {
  String contentType = 'application/json',
}) {
  return MockClient(
    (_) async =>
        http.Response(body, 200, headers: {'content-type': contentType}),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late VersionCheckerService service;

  setUp(() {
    service = VersionCheckerService();
    service.resetForTest();
  });

  tearDown(() => service.resetForTest());

  group('manifest ve apk URL', () {
    test('Android manifest backend PWA yolundan okunur', () async {
      await service.startVersionCheck(
        apiBaseUrl: _apiBaseUrl,
        client: _clientReturning(
          '{"version":"1.0.0","android":{"version":"1.0.0","apk_url":"downloads/a.apk"}}',
        ),
      );

      final uri = service.manifestUri()!;
      expect(uri.origin, 'https://testapp.limak.com.tr');
      expect(uri.path, '/teknofest/app/version.json');
    });

    test('sondaki /api eki temizlenir', () async {
      await service.startVersionCheck(
        apiBaseUrl: '$_apiBaseUrl/api/',
        client: _clientReturning(
          '{"version":"1.0.0","android":{"apk_url":"downloads/a.apk"}}',
        ),
      );
      expect(service.manifestUri()!.path, '/teknofest/app/version.json');
    });

    test('göreli apk_url PWA köküne göre çözülür', () async {
      await service.startVersionCheck(
        apiBaseUrl: _apiBaseUrl,
        client: _clientReturning(
          '{"version":"1.0.0","android":{"apk_url":"downloads/teknofest-yatay-latest.apk"}}',
        ),
      );
      expect(
        service.resolveApkUri('downloads/teknofest-yatay-latest.apk')!.path,
        '/teknofest/app/downloads/teknofest-yatay-latest.apk',
      );
    });

    test('http apk_url reddedilir', () {
      expect(
        service.resolveApkUri(
          'http://testapp.limak.com.tr/teknofest/app/downloads/a.apk',
        ),
        isNull,
      );
    });
  });

  group('senaryolar', () {
    test('senaryo 1: sürüm eşitse update yok', () {
      const manifest = AppUpdateManifest(
        version: '1.0.0',
        build: 1,
        apkUrl: 'downloads/a.apk',
      );
      const running = RunningAppVersion(version: '1.0.0', build: 1);
      expect(manifest.isNewerThan(running), isFalse);
    });

    test('senaryo 2: sunucu yeniyse update var', () {
      const manifest = AppUpdateManifest(
        version: '1.1.0',
        build: 2,
        apkUrl: 'downloads/a.apk',
      );
      const running = RunningAppVersion(version: '1.0.0', build: 1);
      expect(manifest.isNewerThan(running), isTrue);
    });

    test('sunucuya erişilemezse uygulama durumu boş kalır', () async {
      await service.startVersionCheck(
        apiBaseUrl: _apiBaseUrl,
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      expect(service.state.value.updateAvailable, isFalse);
      expect(service.diagnostics.value.lastError, isNotNull);
    });

    test('HTML 200 yanıtı update sayılmaz', () async {
      await service.startVersionCheck(
        apiBaseUrl: _apiBaseUrl,
        client: _clientReturning(
          '<!DOCTYPE html><html></html>',
          contentType: 'text/html',
        ),
      );
      expect(service.state.value.manifest, isNull);
    });
  });

  group('BOM', () {
    test('decodeManifestBody BOM önekini atar', () {
      final bytes = <int>[
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode('{"version":"1.0.2"}'),
      ];
      expect(
        VersionCheckerService.decodeManifestBody(bytes),
        '{"version":"1.0.2"}',
      );
    });
  });

  test('base URL normalize edilir', () {
    expect(
      AppConfig.normalizeBaseUrl('https://testapp.limak.com.tr/teknofest/api/'),
      'https://testapp.limak.com.tr/teknofest',
    );
  });
}
