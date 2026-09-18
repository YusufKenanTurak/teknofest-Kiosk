# Teknofest Kiosk

Bakanlık standı için **1920×1080 landscape** dokunmatik Android kiosk ve
`/teknofest` altında statik Flutter web PWA.

Quiz offline çalışır. APK güncellemesi HTTPS `version.json` üzerinden gelir;
sunucuya ulaşılamazsa test yine açılır.

## Architecture

```
                    INTERNET
                       |
                       v
              testapp.limak.com.tr
                       |
              nginx / TLS edge (mevcut)
                       |
                       v
                      IIS
                       |
             +---------+---------+
             |                   |
             v                   v
       /teknofest          Existing apps
       IIS Application     (EnduransStaff, LTStaff, …)
             |
       +-----+------+
       |            |
       v            v
      PWA         /app
   (publish/)       |
             +------+------+
             |             |
             v             v
       version.json     downloads/teknofest-yatay-latest.apk
```

- **Client:** Flutter / Dart, tek `QuizController` (ChangeNotifier). Named route yok.
- **PWA:** `flutter build web --base-href /teknofest/` → statik dosyalar. Node process yok.
- **Android:** `flutter build apk --release` + `croms_omega_auth` update sözleşmesi.
- **IIS:** `publish/` klasörü `/teknofest` application physical path. Site-level rewrite’e dokunulmaz.
- **Backend (opsiyonel):** [backend/README.md](backend/README.md) PostgreSQL API. `API_BASE_URL` boşsa kiosk offline kalır.

## Local Development

```powershell
flutter pub get
flutter test
flutter run
```

Web’i `/teknofest/` altında denemek için:

```powershell
flutter run -d chrome --web-base-href /teknofest/
```

## Production Build

```powershell
flutter test
.\tool\build_web.ps1
.\tool\publish_web.ps1
.\tool\build_apk.ps1
.\tool\publish_apk.ps1 -Notes "Stand guncellemesi"
```

`pubspec.yaml` `version: 1.0.0+1` tek kaynaktır (`versionName` + `versionCode`).
Build script’ler bunu `version.json` ve dart-define’a yazar.

APK çıktısı: `build/app/outputs/flutter-apk/app-release.apk`  
Paket adı: `tr.limak.teknofest_kiosk_yatay`

`flutter build apk --release` dart-define olmadan gömülü sürüm `9.9.99` olur;
cihaz güncelleme uyarısı çıkarmaz.

## PWA

| | |
|---|---|
| URL | `https://testapp.limak.com.tr/teknofest` |
| Base href | `/teknofest/` |
| Manifest | `/teknofest/manifest.json` |
| `start_url` / `scope` | `/teknofest/` |
| Service worker | `/teknofest/flutter_service_worker.js` (scope `/teknofest/`) |
| Strategy | Flutter `offline-first`; `app/version.json` ve APK build RESOURCES listesinde değildir |

Kiosk uygulamasında GoRouter yok; derin linkler hash/in-memory’dir.
IIS yine de mevcut dosyayı servis eder, `/app/*` ve `assets/` 404’lerini
`index.html`’e düşürmez.

## Android APK

```powershell
.\tool\build_apk.ps1 -UpdateBaseUrl "https://testapp.limak.com.tr/teknofest" -AppEnv test
.\tool\publish_apk.ps1 -Notes "Stand guncellemesi"
```

Gömülen adres: `UPDATE_BASE_URL=https://testapp.limak.com.tr/teknofest`  
HTTP cleartext kapalıdır (`android:usesCleartextTraffic="false"`).  
`http://` APK URL’leri istemcide reddedilir.

## Version Update System

```
Android App
    |
    | GET HTTPS  (Cache-Control: no-cache)
    v
/teknofest/app/version.json
    |
    | remote version/build > running?
    v
android.apk_url
    |
    v
HTTPS APK download (DownloadManager + FileProvider)
```

Sözleşme (croms_omega_auth, `build` = Android `versionCode`):

```json
{
  "version": "1.0.0",
  "versionCode": 1,
  "build": 1,
  "notes": "Stand guncellemesi",
  "android": {
    "version": "1.0.0",
    "versionCode": 1,
    "build": 1,
    "apk_url": "downloads/teknofest-yatay-latest.apk"
  }
}
```

Göreli `apk_url`, `{base}/app/` üzerinden çözülür:

`https://testapp.limak.com.tr/teknofest/app/downloads/teknofest-yatay-latest.apk`

## IIS Deployment

Mevcut site rewrite’leri (**EnduransStaff, LTStaff, ANKStaff, testcontainer**)
değiştirilmez. Teknofest izole IIS Application’dır.

Ayrıntı: [deploy/iis/README.md](deploy/iis/README.md)

```powershell
# 1) Kaynak
cd C:\inetpub\apps
git clone https://github.com/YusufKenanTurak/teknofest-Kiosk.git teknofest-Kiosk
cd teknofest-Kiosk
git checkout main

# 2) Build (sunucuda Flutter yoksa repo icindeki publish/ kullanilir)
.\tool\build_web.ps1
.\tool\publish_web.ps1

# 3) IIS physical path (yalnizca publish icerigi)
.\tool\deploy.ps1 -IisPhysicalPath "C:\inetpub\wwwroot\teknofest"

# 4) Application (bir kez)
.\tool\iis_register_application.ps1 `
  -SiteName "<mevcut site adi>" `
  -PhysicalPath "C:\inetpub\wwwroot\teknofest"
```

`web.config` `publish/` içindedir: APK MIME, JSON MIME, cache, SPA fallback.
Site köküne kural eklemeye gerek yoktur.

Public hostname şu an nginx 404 dönüyorsa, edge’in `/teknofest` isteğini IIS
application’a iletmesi gerekir. Bu repo nginx conf’una dokunmaz.

## Directory Structure

```
publish/                          IIS physical path
  web.config                      /teknofest uygulama kurallari
  index.html, flutter.js, ...     PWA
  assets/, canvaskit/, icons/
  app/
    version.json                  no-cache JSON
    downloads/
      teknofest-yatay-latest.apk  gitignore; deploy korur
tool/
  build_web.ps1 / publish_web.ps1
  build_apk.ps1 / publish_apk.ps1
  write_version_manifest.ps1
  deploy.ps1 / health_check.ps1
  iis_register_application.ps1
```

## Update Flow

1. Kiosk 5 dakikada bir `GET /teknofest/app/version.json` (no-cache).
2. HTML gelirse (yanlış SPA fallback) güncelleme yok sayılır.
3. `android` bloğu + `apk_url` yoksa Android release sayılmaz.
4. `version` / `build` (`versionCode`) yüklü APK’den yeniyse diyalog açılır.
5. APK HTTPS’ten iner; `teknofest-yatay-latest.apk` sabit URL’dir.
6. Sürüm bilgisi `version.json` ile değişir; URL değişmez.

## Troubleshooting

| Belirti | Kontrol |
|---|---|
| `version.json` HTML | `/app/` IIS fallback’e gidiyor; `publish/web.config` application’da mı? |
| APK `text/html` | Aynı; MIME `application/vnd.android.package-archive` |
| 404 tüm `/teknofest` | IIS application yok veya nginx `/teknofest` geçirmiyor |
| Eski APK iniyor | APK `no-store`; tarayıcı değil kiosk DownloadManager kullanır |
| SW başka uygulamayı bozuyor | SW `/teknofest/flutter_service_worker.js` — `Service-Worker-Allowed: /` header’ı eklemeyin |
| Diğer PWA’lar kırıldı | Site-level rewrite’e Teknofest kuralı yapıştırılmamalı |

```powershell
curl.exe -I https://testapp.limak.com.tr/teknofest
curl.exe -I https://testapp.limak.com.tr/teknofest/app/version.json
curl.exe -I https://testapp.limak.com.tr/teknofest/app/downloads/teknofest-yatay-latest.apk
```

## Rollback

`deploy.ps1` her seferinde `publish/` içeriğini IIS path’e kopyalar.
Önceki çalışan Git commit’e dönmek:

```powershell
cd C:\inetpub\apps\teknofest-Kiosk
git fetch origin
git checkout <onceki-commit>
.\tool\deploy.ps1 -IisPhysicalPath "C:\inetpub\wwwroot\teknofest" -SkipBuild
```

APK yeni dosya yoksa mevcut `teknofest-yatay-latest.apk` silinmez.

## Cache

| Kaynak | Cache-Control |
|---|---|
| `index.html`, bootstrap, SW, manifest | no-cache |
| `app/version.json`, APK | no-cache, no-store, must-revalidate |
| `assets/`, `canvaskit/` (hash’li) | 1 yıl, immutable |

## Kiosk davranışı

- Landscape kilit, immersive sticky, ekranı açık tutma
- Sistem geri tuşu yutulur, HOME intent-filter
- 30 sn hareketsizlikte oturum sıfırlanır

## Test

```powershell
flutter test
```

Manuel: [MANUAL_KIOSK_TEST.md](MANUAL_KIOSK_TEST.md)
