import 'package:flutter_test/flutter_test.dart';
import 'package:teknofest_kiosk/app_update/app_version.dart';

void main() {
  group('compareAppVersions', () {
    test('eşit sürümler', () {
      expect(compareAppVersions('1.2.3', '1.2.3'), 0);
    });

    test('çift haneli yama sürümü doğru sıralanır', () {
      expect(compareAppVersions('1.0.10', '1.0.9'), 1);
      expect(compareAppVersions('1.0.10', '1.1.0'), -1);
    });

    test('build eki semantik karşılaştırmayı etkilemez', () {
      expect(compareAppVersions('1.2.3+40', '1.2.3+9'), 0);
    });
  });

  group('isRemoteAppVersionNewer', () {
    test('aynı sürümün yeni build numarası güncelleme sayılır', () {
      expect(
        isRemoteAppVersionNewer(
          currentVersion: '1.0.1',
          currentBuild: 2,
          remoteVersion: '1.0.1',
          remoteBuild: 3,
        ),
        isTrue,
      );
    });

    test('aynı sürüm ve aynı build güncelleme değildir', () {
      expect(
        isRemoteAppVersionNewer(
          currentVersion: '1.0.1',
          currentBuild: 2,
          remoteVersion: '1.0.1',
          remoteBuild: 2,
        ),
        isFalse,
      );
    });

    test('sürüm artışı build numarasından bağımsız kazanır', () {
      expect(
        isRemoteAppVersionNewer(
          currentVersion: '1.0.0',
          currentBuild: 1,
          remoteVersion: '1.1.0',
          remoteBuild: 1,
        ),
        isTrue,
      );
    });
  });
}
