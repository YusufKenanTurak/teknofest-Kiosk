import 'package:flutter_test/flutter_test.dart';
import 'package:teknofest_kiosk/config/app_config.dart';
import 'package:teknofest_kiosk/config/external_browser.dart';

void main() {
  test('TMK URL is https and on the allow-list', () {
    final uri = Uri.parse(AppConfig.tmkUrl);
    expect(ExternalBrowser.isAllowed(uri), isTrue);
  });

  test('non-https and unknown hosts are rejected', () {
    expect(ExternalBrowser.isAllowed(Uri.parse('http://example.com')), isFalse);
    expect(
      ExternalBrowser.isAllowed(Uri.parse('https://evil.example')),
      isFalse,
    );
  });

  test('openConfigured uses the injected opener for allowed URLs', () async {
    Uri? opened;
    ExternalBrowser.open = (uri) async {
      opened = uri;
      return true;
    };
    addTearDown(() {
      ExternalBrowser.open = ExternalBrowser.openExternal;
    });

    final ok = await ExternalBrowser.openTmkSite();
    expect(ok, isTrue);
    expect(opened, Uri.parse(AppConfig.tmkUrl));
  });
}
