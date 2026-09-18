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
- **IIS:** sunucuda `C:\Users\yturak\Desktop\teknofest-Kiosk\publish` klasörü `/teknofest` physical path. Site-level rewrite’e dokunulmaz. `inetpub` kullanılmaz.
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

**Sunucuda Flutter yoktur.** Derleme bu PC’de alınır. IIS host checkout:

`C:\Users\yturak\Desktop\teknofest-Kiosk`

`/teknofest` physical path yalnızca `publish\` (kaynak `lib\` servis edilmez).
`C:\inetpub` kullanılmaz. Mevcut site rewrite’leri (**EnduransStaff, LTStaff,
ANKStaff, testcontainer**) değiştirilmez.

Ayrıntı: [deploy/iis/README.md](deploy/iis/README.md)

### 1) Bu PC — build

```powershell
cd "<repo>"
flutter test
.\tool\build_web.ps1
.\tool\publish_web.ps1
.\tool\build_apk.ps1
.\tool\publish_apk.ps1 -Notes "Stand release"
.\tool\package_release.ps1
```

Çıktı: `dist\teknofest-iis-latest.zip`

### 2) Sunucuya koy

Tüm repo + `publish\` zaten şurada olmalı:

`C:\Users\yturak\Desktop\teknofest-Kiosk`

Yeni zip varsa: `C:\Users\yturak\Desktop\teknofest-Kiosk\dist\teknofest-iis-latest.zip`

Paylaşım ile yalnızca PWA:

```powershell
.\tool\copy_publish.ps1 `
  -PublishDir ".\publish" `
  -IisPhysicalPath "\\SUNUCU\C$\Users\yturak\Desktop\teknofest-Kiosk\publish"
```

### 3) Sunucu — Flutter yok

```powershell
Import-Module WebAdministration
Get-Website
Get-WebApplication
Get-WebBinding

cd C:\Users\yturak\Desktop\teknofest-Kiosk

# Dosyalar zaten bu klasordeyse:
.\tool\deploy.ps1 -SkipPwaBuild

# Yeni zip geldiyse:
.\tool\deploy.ps1 -SkipPwaBuild -FromZip ".\dist\teknofest-iis-latest.zip"

# Application (bir kez; SiteName = Get-Website). Physical path varsayilan publish\
.\tool\iis_register_application.ps1 -SiteName "<mevcut site adi>"
```

`deploy.ps1` `-SkipPwaBuild` olmadan çalışmaz. IIS application `publish\`
dışına bakıyorsa `iis_register_application.ps1` physical path’i buraya çeker.

### 4) Health check (bu PC veya sunucu)

```powershell
curl.exe -I https://testapp.limak.com.tr/teknofest
curl.exe -I https://testapp.limak.com.tr/teknofest/app/version.json
curl.exe -I https://testapp.limak.com.tr/teknofest/app/downloads/teknofest-yatay-latest.apk
.\tool\health_check.ps1
```

`web.config` `publish/` içindedir. Site köküne kural eklemeyin.

Public hostname nginx 404 dönüyorsa edge `/teknofest` isteğini IIS application’a
iletmelidir. Bu repo nginx conf’una dokunmaz.

## Directory Structure

```
C:\Users\yturak\Desktop\teknofest-Kiosk\   sunucu checkout (inetpub yok)
  publish\                                IIS /teknofest physical path
    web.config
    index.html, flutter.js, ...
    assets/, canvaskit/, icons/
    app\
      version.json
      downloads\teknofest-yatay-latest.apk
  drop\                                   zip acma (opsiyonel)
  dist\                                   gelen zip (opsiyonel)
  tool\
    server_paths.ps1
    build_web.ps1 / publish_web.ps1       bu PC
    build_apk.ps1 / publish_apk.ps1       bu PC
    package_release.ps1
    copy_publish.ps1 / deploy.ps1
    health_check.ps1
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
| 401.3 / boş site | Desktop ACL; `iis_register_application.ps1` app pool’a RX verir |
| Eski APK iniyor | APK `no-store`; tarayıcı değil kiosk DownloadManager kullanır |
| SW başka uygulamayı bozuyor | SW `/teknofest/flutter_service_worker.js` — `Service-Worker-Allowed: /` header’ı eklemeyin |
| Diğer PWA’lar kırıldı | Site-level rewrite’e Teknofest kuralı yapıştırılmamalı |

```powershell
curl.exe -I https://testapp.limak.com.tr/teknofest
curl.exe -I https://testapp.limak.com.tr/teknofest/app/version.json
curl.exe -I https://testapp.limak.com.tr/teknofest/app/downloads/teknofest-yatay-latest.apk
```

## Rollback

Önceki zip’i tekrar açıp aynı `SkipPwaBuild` kopyasını çalıştırın:

```powershell
cd C:\Users\yturak\Desktop\teknofest-Kiosk
.\tool\deploy.ps1 -SkipPwaBuild -FromZip ".\dist\teknofest-iis-<onceki>.zip"
```

APK yeni pakette yoksa mevcut `teknofest-yatay-latest.apk` silinmez.

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
