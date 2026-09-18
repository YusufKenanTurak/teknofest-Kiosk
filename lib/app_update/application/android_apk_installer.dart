import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../running_app_version.dart';

enum ApkDownloadStatus { idle, pending, running, paused, successful, failed }

class ApkDownloadProgress {
  const ApkDownloadProgress({
    required this.status,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.error,
  });

  static const idle = ApkDownloadProgress(status: ApkDownloadStatus.idle);

  final ApkDownloadStatus status;
  final int downloadedBytes;
  final int totalBytes;
  final String? error;

  bool get isFinished =>
      status == ApkDownloadStatus.successful ||
      status == ApkDownloadStatus.failed;

  double? get fraction {
    if (totalBytes <= 0) return null;
    return (downloadedBytes / totalBytes).clamp(0.0, 1.0);
  }

  factory ApkDownloadProgress.fromMap(Map<Object?, Object?> map) {
    return ApkDownloadProgress(
      status: _statusFromName(map['status'] as String?),
      downloadedBytes: (map['downloadedBytes'] as num?)?.toInt() ?? 0,
      totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
      error: map['error'] as String?,
    );
  }

  static ApkDownloadStatus _statusFromName(String? name) {
    return switch (name) {
      'pending' => ApkDownloadStatus.pending,
      'running' => ApkDownloadStatus.running,
      'paused' => ApkDownloadStatus.paused,
      'successful' => ApkDownloadStatus.successful,
      'failed' => ApkDownloadStatus.failed,
      _ => ApkDownloadStatus.idle,
    };
  }
}

/// Android APK indirme / kurulum. Referans: croms_omega_auth + VardiyaTakip
/// `AppUpdateHelper` (DownloadManager + FileProvider).
class AndroidApkInstaller {
  const AndroidApkInstaller._();

  static const MethodChannel channel = MethodChannel(
    'tr.limak.teknofest_kiosk_yatay/app_update',
  );

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<bool> canInstallPackages() async {
    if (!isSupported) return false;
    try {
      return await channel.invokeMethod<bool>('canInstallPackages') ?? false;
    } on PlatformException catch (e) {
      debugPrint('[UPDATE] izin durumu okunamadı — ${e.message}');
      return false;
    }
  }

  static Future<void> openInstallPermissionSettings() async {
    if (!isSupported) return;
    try {
      await channel.invokeMethod<void>('openInstallPermissionSettings');
    } on PlatformException catch (e) {
      debugPrint('[UPDATE] izin ekranı açılamadı — ${e.message}');
    }
  }

  static Future<int?> startDownload({
    required String url,
    required String version,
  }) async {
    if (!isSupported) return null;
    return channel.invokeMethod<int>('startDownload', {
      'url': url,
      'version': version,
    });
  }

  static Future<ApkDownloadProgress> downloadProgress(int downloadId) async {
    if (!isSupported) return ApkDownloadProgress.idle;
    final result = await channel.invokeMethod<Map<Object?, Object?>>(
      'downloadProgress',
      {'downloadId': downloadId},
    );
    if (result == null) return ApkDownloadProgress.idle;
    return ApkDownloadProgress.fromMap(result);
  }

  static Future<bool> install(int downloadId) async {
    if (!isSupported) return false;
    return await channel.invokeMethod<bool>('install', {
          'downloadId': downloadId,
        }) ??
        false;
  }

  static Future<RunningAppVersion?> readInstalledVersion() async {
    if (!isSupported) return null;
    try {
      final result = await channel.invokeMethod<Map<Object?, Object?>>(
        'getInstalledVersion',
      );
      if (result == null) return null;
      final version = (result['version'] as String?)?.trim();
      if (version == null || version.isEmpty) return null;
      final build = (result['build'] as num?)?.toInt() ?? 0;
      return RunningAppVersion(version: version, build: build);
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint('[UPDATE] yüklü sürüm okunamadı — ${e.message}');
      return null;
    } catch (e) {
      debugPrint('[UPDATE] yüklü sürüm okunamadı — $e');
      return null;
    }
  }

  static Future<void> cancelDownload(int downloadId) async {
    if (!isSupported) return;
    try {
      await channel.invokeMethod<void>('cancelDownload', {
        'downloadId': downloadId,
      });
    } on PlatformException catch (e) {
      debugPrint('[UPDATE] indirme iptal edilemedi — ${e.message}');
    }
  }
}
