import 'dart:async';

import 'package:flutter/material.dart';

import '../application/android_apk_installer.dart';
import '../application/version_checker_service.dart' as app_update;
import '../domain/app_update_models.dart';
import '../running_app_version.dart';

enum _UpdatePhase { idle, downloading, readyToInstall, needsPermission, failed }

enum AppUpdateDialogResult { later, completed }

/// Referans UI: croms_omega_auth `AppUpdateDialog`.
class AppUpdateDialog extends StatefulWidget {
  AppUpdateDialog({
    super.key,
    required this.state,
    app_update.VersionCheckerService? checker,
  }) : versionChecker = checker ?? app_update.versionChecker;

  final AppUpdateState state;
  final app_update.VersionCheckerService versionChecker;

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  _UpdatePhase _phase = _UpdatePhase.idle;
  ApkDownloadProgress _progress = ApkDownloadProgress.idle;
  Timer? _progressTimer;
  int? _downloadId;
  String? _error;

  AppUpdateManifest get _manifest => widget.state.manifest!;

  bool get _isMandatory => widget.state.isMandatory;

  bool get _isBusy =>
      _phase == _UpdatePhase.downloading ||
      _phase == _UpdatePhase.readyToInstall;

  bool get _canDismiss => !_isMandatory && !_isBusy;

  RunningAppVersion get _running =>
      widget.state.runningVersion ?? RunningAppVersion.fromEmbedded();

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _onPrimaryAction() async {
    if (_phase == _UpdatePhase.failed) {
      setState(() {
        _phase = _UpdatePhase.idle;
        _error = null;
      });
    }

    if (!widget.state.canInstallInPlace) {
      setState(() {
        _phase = _UpdatePhase.failed;
        _error =
            'Güncelleme paketi sunucuda tanımlı değil. Yöneticinizin APK\'yı '
            'version.json içindeki android.apk_url alanıyla yayınlaması gerekir.';
      });
      return;
    }
    await _startAndroidUpdate();
  }

  Future<void> _startAndroidUpdate() async {
    final apkUri = widget.versionChecker.resolveApkUri(_manifest.apkUrl ?? '');
    if (apkUri == null) {
      setState(() {
        _phase = _UpdatePhase.failed;
        _error = 'Güncelleme paketinin adresi çözülemedi.';
      });
      return;
    }

    if (!await AndroidApkInstaller.canInstallPackages()) {
      if (!mounted) return;
      setState(() => _phase = _UpdatePhase.needsPermission);
      return;
    }

    debugPrint('[UPDATE] Download started');
    setState(() {
      _phase = _UpdatePhase.downloading;
      _progress = const ApkDownloadProgress(status: ApkDownloadStatus.pending);
      _error = null;
    });

    try {
      final downloadId = await AndroidApkInstaller.startDownload(
        url: apkUri.toString(),
        version: _manifest.label,
      );
      if (downloadId == null) throw StateError('İndirme başlatılamadı');
      _downloadId = downloadId;
      _watchProgress(downloadId);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _UpdatePhase.failed;
        _error = 'İndirme başlatılamadı: $e';
      });
    }
  }

  void _watchProgress(int downloadId) {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 700), (
      timer,
    ) async {
      final progress = await AndroidApkInstaller.downloadProgress(downloadId);
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() => _progress = progress);
      if (!progress.isFinished) return;

      timer.cancel();
      if (progress.status == ApkDownloadStatus.failed) {
        debugPrint('[UPDATE] Download failed — ${progress.error}');
        setState(() {
          _phase = _UpdatePhase.failed;
          _error = progress.error ?? 'Güncelleme indirilemedi.';
        });
        return;
      }

      debugPrint('[UPDATE] Download completed');
      debugPrint('[UPDATE] APK validation successful');
      setState(() => _phase = _UpdatePhase.readyToInstall);
      await _install(downloadId);
    });
  }

  Future<void> _install(int downloadId) async {
    debugPrint('[UPDATE] Installation started');
    final started = await AndroidApkInstaller.install(downloadId);
    if (!mounted) return;
    if (started) {
      Navigator.of(context).pop(AppUpdateDialogResult.completed);
      return;
    }
    setState(() {
      _phase = _UpdatePhase.failed;
      _error =
          'Kurulum başlatılamadı. İndirilen dosya geçerli bir APK değil; '
          'sunucu yanlış dosya döndürmüş olabilir (404 sayfası).';
    });
  }

  Future<void> _grantInstallPermission() async {
    await AndroidApkInstaller.openInstallPermissionSettings();
    if (!mounted) return;
    setState(() => _phase = _UpdatePhase.idle);
  }

  void _dismiss() {
    _progressTimer?.cancel();
    final downloadId = _downloadId;
    if (downloadId != null && _phase == _UpdatePhase.downloading) {
      unawaited(AndroidApkInstaller.cancelDownload(downloadId));
    }
    Navigator.of(context).pop(AppUpdateDialogResult.later);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: _canDismiss,
      child: AlertDialog(
        icon: Icon(
          Icons.system_update_rounded,
          size: 48,
          color: theme.colorScheme.primary,
        ),
        title: Text(_isMandatory ? 'Güncelleme Gerekli' : 'Yeni Sürüm Mevcut'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_description, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Mevcut sürüm: ${_running.label}\nYeni sürüm: ${_manifest.label}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              if (_manifest.notes case final notes? when notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  notes,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (_phase == _UpdatePhase.downloading ||
                  _phase == _UpdatePhase.readyToInstall) ...[
                const SizedBox(height: 20),
                LinearProgressIndicator(value: _progress.fraction),
                const SizedBox(height: 8),
                Text(
                  _progressLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (_error case final error?) ...[
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: _buildActions(),
      ),
    );
  }

  String get _description {
    if (_phase == _UpdatePhase.needsPermission) {
      return 'Güncellemenin kurulabilmesi için bu uygulamaya "bilinmeyen '
          'kaynaklardan yükleme" izni vermeniz gerekiyor. İzni verdikten sonra '
          'bu ekrana dönüp tekrar deneyin.';
    }
    if (_isMandatory) {
      return 'Kullandığınız sürüm artık desteklenmiyor. Devam etmek için '
          'uygulamayı güncelleyin.';
    }
    return 'Uygulamanın yeni bir sürümü yayınlandı. APK indirilecek ve '
        'mevcut uygulamanın üzerine kurulacak.';
  }

  String get _progressLabel {
    if (_phase == _UpdatePhase.readyToInstall) return 'Kurulum başlatılıyor...';
    final fraction = _progress.fraction;
    if (fraction == null) return 'İndiriliyor...';
    return 'İndiriliyor — %${(fraction * 100).round()}';
  }

  List<Widget> _buildActions() {
    if (_phase == _UpdatePhase.needsPermission) {
      return [
        if (!_isMandatory)
          TextButton(onPressed: _dismiss, child: const Text('Daha Sonra')),
        FilledButton(
          onPressed: _grantInstallPermission,
          child: const Text('İzin Ver'),
        ),
      ];
    }

    if (_isBusy) {
      return [
        TextButton(
          onPressed: _phase == _UpdatePhase.downloading ? _dismiss : null,
          child: const Text('İptal'),
        ),
      ];
    }

    return [
      if (!_isMandatory)
        TextButton(onPressed: _dismiss, child: const Text('Daha Sonra')),
      FilledButton(
        onPressed: _onPrimaryAction,
        child: Text(_primaryActionLabel),
      ),
    ];
  }

  String get _primaryActionLabel {
    if (_phase == _UpdatePhase.failed) return 'Tekrar Dene';
    return 'Versiyonu Güncelle';
  }
}
