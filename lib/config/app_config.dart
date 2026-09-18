/// Güncelleme taban URL'si tek kaynaktan okunur.
///
/// Derleme:
/// `--dart-define=UPDATE_BASE_URL=https://testapp.limak.com.tr/teknofest`
class AppConfig {
  const AppConfig._();

  static const String defaultUpdateBaseUrl =
      'https://testapp.limak.com.tr/teknofest';

  static const String updateBaseUrl = String.fromEnvironment(
    'UPDATE_BASE_URL',
    defaultValue: defaultUpdateBaseUrl,
  );

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'test',
  );

  static const String defaultTmkUrl =
      'https://www.turkiyeninmuhendiskizlari.com/';

  static const String tmkUrl = String.fromEnvironment(
    'TMK_URL',
    defaultValue: defaultTmkUrl,
  );

  /// Optional persistence API. Empty keeps the kiosk fully offline.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String kioskId = String.fromEnvironment(
    'KIOSK_ID',
    defaultValue: 'stand',
  );

  static String normalizeBaseUrl(String url) {
    var normalized = url.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    for (final suffix in ['/docs', '/qr', '/redoc', '/health']) {
      if (normalized.endsWith(suffix)) {
        normalized = normalized.substring(0, normalized.length - suffix.length);
      }
    }
    if (normalized.endsWith('/api')) {
      normalized = normalized.substring(0, normalized.length - 4);
    }
    return normalized;
  }
}
