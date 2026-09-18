import 'package:url_launcher/url_launcher.dart';

import 'app_config.dart';

/// Opens https URLs outside the kiosk. Overridable in tests.
class ExternalBrowser {
  ExternalBrowser._();

  static const Set<String> allowedHosts = {
    'www.turkiyeninmuhendiskizlari.com',
    'turkiyeninmuhendiskizlari.com',
    'turkiye.globalengineergirls.com',
    'www.limak.com.tr',
    'limak.com.tr',
  };

  static Future<bool> Function(Uri uri) open = openExternal;

  static Future<bool> openExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static bool isAllowed(Uri uri) {
    if (!uri.isScheme('https')) {
      return false;
    }
    return allowedHosts.contains(uri.host);
  }

  static Future<bool> openConfigured(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !isAllowed(uri)) {
      return false;
    }
    return open(uri);
  }

  static Future<bool> openTmkSite() => openConfigured(AppConfig.tmkUrl);
}
