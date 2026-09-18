import 'dart:async';

import 'package:flutter/material.dart';

import '../application/version_checker_service.dart' as app_update;
import '../domain/app_update_models.dart';
import 'app_update_dialog.dart';

/// Referans: croms_omega_auth `AppUpdateHost`.
class AppUpdateHost extends StatefulWidget {
  AppUpdateHost({
    super.key,
    required this.child,
    this.resolveApiBaseUrl,
    app_update.VersionCheckerService? checker,
  }) : versionChecker = checker ?? app_update.versionChecker;

  final Widget child;
  final Future<String?> Function()? resolveApiBaseUrl;
  final app_update.VersionCheckerService versionChecker;

  @override
  State<AppUpdateHost> createState() => _AppUpdateHostState();
}

class _AppUpdateHostState extends State<AppUpdateHost>
    with WidgetsBindingObserver {
  bool _dialogVisible = false;
  String? _postponedLabel;

  app_update.VersionCheckerService get _checker => widget.versionChecker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checker.state.addListener(_onUpdateState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onUpdateState());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_syncApiBaseUrl());
  }

  Future<void> _syncApiBaseUrl() async {
    final resolver = widget.resolveApiBaseUrl;
    if (resolver == null) return;

    try {
      final apiUrl = await resolver();
      _checker.updateApiBaseUrl(apiUrl);
      if (mounted && _checker.isStarted) {
        unawaited(_checker.checkNow());
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _checker.state.removeListener(_onUpdateState);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _checker.isStarted) {
      unawaited(_checker.checkNow());
    }
  }

  void _onUpdateState() {
    if (!mounted || _dialogVisible) return;

    final state = _checker.state.value;
    if (!state.updateAvailable) return;

    final label = state.manifest?.label;
    if (!state.isMandatory && label != null && label == _postponedLabel) {
      return;
    }

    unawaited(_showUpdateDialog(state));
  }

  Future<void> _showUpdateDialog(AppUpdateState state) async {
    _dialogVisible = true;
    try {
      final result = await showDialog<AppUpdateDialogResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            AppUpdateDialog(state: state, checker: widget.versionChecker),
      );
      if (result == AppUpdateDialogResult.later) {
        _postponedLabel = state.manifest?.label;
      }
    } finally {
      _dialogVisible = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
