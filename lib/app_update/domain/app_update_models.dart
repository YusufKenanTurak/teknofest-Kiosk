import '../app_version.dart';
import '../running_app_version.dart';

enum AppUpdateChannel { web, android, ios }

/// Sunucudaki `version.json` içeriğinin tek kanal için çözülmüş hali.
///
/// Referans şema (croms_omega_auth / VardiyaTakip):
/// ```json
/// {
///   "version": "1.2.0",
///   "build": 20,
///   "min_supported_version": "1.1.0",
///   "notes": "...",
///   "android": { "version": "1.2.0", "build": 20, "apk_url": "downloads/teknofest-yatay-latest.apk" }
/// }
/// ```
class AppUpdateManifest {
  const AppUpdateManifest({
    required this.version,
    this.build,
    this.minSupportedVersion,
    this.forceLogout = false,
    this.notes,
    this.apkUrl,
  });

  final String version;
  final int? build;
  final String? minSupportedVersion;
  final bool forceLogout;
  final String? notes;
  final String? apkUrl;

  static AppUpdateManifest? tryParse(
    Map<String, dynamic> json,
    AppUpdateChannel channel,
  ) {
    final scoped = json[_channelKey(channel)];
    final overrides = scoped is Map<String, dynamic>
        ? scoped
        : const <String, dynamic>{};

    if (channel != AppUpdateChannel.web && overrides.isEmpty) return null;

    final version = _string(overrides['version']) ?? _string(json['version']);
    if (version == null || version.isEmpty) return null;

    final apkUrl =
        _string(overrides['apk_url']) ??
        _string(overrides['apkUrl']) ??
        _string(json['apk_url']) ??
        _string(json['apkUrl']);
    if (channel == AppUpdateChannel.android && apkUrl == null) return null;

    return AppUpdateManifest(
      version: version,
      build:
          _int(overrides['build']) ??
          _int(overrides['versionCode']) ??
          _int(json['build']) ??
          _int(json['versionCode']),
      minSupportedVersion:
          _string(overrides['min_supported_version']) ??
          _string(json['min_supported_version']),
      forceLogout:
          _bool(overrides['force_logout']) ??
          _bool(json['force_logout']) ??
          false,
      notes:
          _string(overrides['notes']) ??
          _string(json['notes']) ??
          _string(json['releaseNotes']),
      apkUrl: apkUrl,
    );
  }

  bool isNewerThan(RunningAppVersion running) => isRemoteAppVersionNewer(
    currentVersion: running.version,
    currentBuild: running.build,
    remoteVersion: version,
    remoteBuild: build,
  );

  bool isUpdatePending({
    required RunningAppVersion running,
    String? acknowledgedLabel,
  }) {
    if (isNewerThan(running)) return true;
    final ack = acknowledgedLabel?.trim();
    if (ack == null || ack.isEmpty) return false;
    final parts = parseAppVersionLabel(ack);
    if (parts == null) return false;
    return isRemoteAppVersionNewer(
      currentVersion: parts.version,
      currentBuild: parts.build,
      remoteVersion: version,
      remoteBuild: build,
    );
  }

  bool isMandatoryFor(RunningAppVersion running) {
    final minimum = minSupportedVersion;
    if (minimum == null || minimum.isEmpty) return false;
    return isAppVersionOlder(running.version, minimum);
  }

  String get label => build != null ? '$version+$build' : version;

  static String _channelKey(AppUpdateChannel channel) => switch (channel) {
    AppUpdateChannel.web => 'web',
    AppUpdateChannel.android => 'android',
    AppUpdateChannel.ios => 'ios',
  };

  static String? _string(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static bool? _bool(Object? value) {
    if (value is bool) return value;
    if (value is String) {
      return bool.tryParse(value.trim(), caseSensitive: false);
    }
    return null;
  }
}

class AppUpdateDiagnostics {
  const AppUpdateDiagnostics({
    this.manifestUrl,
    this.lastCheckedAt,
    this.lastError,
    this.remoteLabel,
  });

  final String? manifestUrl;
  final DateTime? lastCheckedAt;
  final String? lastError;
  final String? remoteLabel;

  bool get hasChecked => lastCheckedAt != null;
  bool get isHealthy => lastError == null && remoteLabel != null;
}

class AppUpdateState {
  const AppUpdateState({
    required this.channel,
    this.manifest,
    this.lastCheckedAt,
    this.acknowledgedVersion,
    this.runningVersion,
  });

  const AppUpdateState.idle()
    : channel = AppUpdateChannel.android,
      manifest = null,
      lastCheckedAt = null,
      acknowledgedVersion = null,
      runningVersion = null;

  final AppUpdateChannel channel;
  final AppUpdateManifest? manifest;
  final DateTime? lastCheckedAt;
  final String? acknowledgedVersion;
  final RunningAppVersion? runningVersion;

  bool get updateAvailable {
    final manifest = this.manifest;
    final running = runningVersion;
    if (manifest == null || running == null) return false;
    return manifest.isUpdatePending(
      running: running,
      acknowledgedLabel: acknowledgedVersion,
    );
  }

  bool get isMandatory =>
      manifest?.isMandatoryFor(
        runningVersion ?? RunningAppVersion.fromEmbedded(),
      ) ??
      false;

  bool get canInstallInPlace =>
      channel == AppUpdateChannel.android &&
      (manifest?.apkUrl?.isNotEmpty ?? false);

  AppUpdateState copyWith({
    AppUpdateChannel? channel,
    AppUpdateManifest? manifest,
    DateTime? lastCheckedAt,
    String? acknowledgedVersion,
    RunningAppVersion? runningVersion,
  }) {
    return AppUpdateState(
      channel: channel ?? this.channel,
      manifest: manifest ?? this.manifest,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      acknowledgedVersion: acknowledgedVersion ?? this.acknowledgedVersion,
      runningVersion: runningVersion ?? this.runningVersion,
    );
  }
}

({String version, int build})? parseAppVersionLabel(String label) {
  final trimmed = label.trim();
  if (trimmed.isEmpty) return null;

  final parts = trimmed.split('+');
  final version = parts.first.trim();
  if (version.isEmpty) return null;

  final build = parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 0 : 0;
  return (version: version, build: build);
}
