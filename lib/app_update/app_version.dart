/// Derleme anında koda gömülen uygulama sürümü.
///
/// Referans: croms_omega_auth `AppVersion`. Testlerde dart-define yoksa
/// bilinçli olarak yüksek bir değer kullanılır; güncelleme uyarısı çıkmaz.
class AppVersion {
  const AppVersion._();

  static const String developmentVersion = '9.9.99';

  static const String currentVersion = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: developmentVersion,
  );

  static const int currentBuild = int.fromEnvironment('APP_BUILD');

  static bool get isDevelopmentBuild => currentVersion == developmentVersion;

  static String get label =>
      currentBuild > 0 ? '$currentVersion+$currentBuild' : currentVersion;
}

int compareAppVersions(String a, String b) {
  final left = _versionSegments(a);
  final right = _versionSegments(b);
  final length = left.length > right.length ? left.length : right.length;

  for (var i = 0; i < length; i++) {
    final l = i < left.length ? left[i] : 0;
    final r = i < right.length ? right[i] : 0;
    if (l != r) return l < r ? -1 : 1;
  }
  return 0;
}

bool isAppVersionOlder(String current, String other) =>
    compareAppVersions(current, other) < 0;

/// Semantik sürüm + build (versionCode). Düz string karşılaştırması yok.
bool isRemoteAppVersionNewer({
  required String currentVersion,
  required int currentBuild,
  required String remoteVersion,
  int? remoteBuild,
}) {
  final comparison = compareAppVersions(currentVersion, remoteVersion);
  if (comparison != 0) return comparison < 0;

  if (remoteBuild == null || currentBuild <= 0) return false;
  return currentBuild < remoteBuild;
}

List<int> _versionSegments(String version) {
  final normalized = version.trim().split('+').first;
  if (normalized.isEmpty) return const [0];

  return normalized
      .split('.')
      .map(
        (segment) => int.tryParse(segment.replaceAll(RegExp(r'\D'), '')) ?? 0,
      )
      .toList(growable: false);
}
