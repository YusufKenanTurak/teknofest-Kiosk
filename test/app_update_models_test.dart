import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:teknofest_kiosk/app_update/domain/app_update_models.dart';
import 'package:teknofest_kiosk/app_update/running_app_version.dart';

Map<String, dynamic> _json(String source) =>
    jsonDecode(source) as Map<String, dynamic>;

void main() {
  test('PWA-only manifest Android güncellemesi sayılmaz', () {
    expect(
      AppUpdateManifest.tryParse(
        _json('{"version": "1.2.0", "build": 20}'),
        AppUpdateChannel.android,
      ),
      isNull,
    );
  });

  test('APK URL olmayan Android bloğu release sayılmaz', () {
    expect(
      AppUpdateManifest.tryParse(
        _json('{"version": "1.2.0", "android": {"version": "1.2.0"}}'),
        AppUpdateChannel.android,
      ),
      isNull,
    );
  });

  test('kanal bloğu kök değerleri ezer', () {
    final android = AppUpdateManifest.tryParse(
      _json('''
        {
          "version": "1.2.0",
          "android": {
            "version": "1.3.0",
            "apk_url": "downloads/teknofest-yatay-latest.apk"
          }
        }
      '''),
      AppUpdateChannel.android,
    )!;
    expect(android.version, '1.3.0');
    expect(android.apkUrl, 'downloads/teknofest-yatay-latest.apk');
  });

    test('yüklü sürüm gerideyse güncelleme bekler', () {
    const manifest = AppUpdateManifest(version: '1.1.0', build: 2);
    const running = RunningAppVersion(version: '1.0.0', build: 1);
    expect(manifest.isUpdatePending(running: running), isTrue);
  });

  test('versionCode ve apkUrl alias olarak okunur', () {
    final android = AppUpdateManifest.tryParse(
      _json('''
        {
          "version": "1.0.0",
          "android": {
            "version": "1.0.1",
            "versionCode": 3,
            "apkUrl": "downloads/teknofest-yatay-latest.apk"
          }
        }
      '''),
      AppUpdateChannel.android,
    )!;
    expect(android.version, '1.0.1');
    expect(android.build, 3);
    expect(android.apkUrl, 'downloads/teknofest-yatay-latest.apk');
  });
}
