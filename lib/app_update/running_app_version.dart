import 'app_version.dart';

/// Güncelleme karşılaştırmasında kullanılan çalışan sürüm.
/// Android'de PackageManager versionCode / versionName okunur.
class RunningAppVersion {
  const RunningAppVersion({required this.version, required this.build});

  final String version;
  final int build;

  String get label => build > 0 ? '$version+$build' : version;

  factory RunningAppVersion.fromEmbedded() => RunningAppVersion(
    version: AppVersion.currentVersion,
    build: AppVersion.currentBuild,
  );
}
