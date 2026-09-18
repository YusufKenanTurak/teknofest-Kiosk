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
.\tool\package_release.ps1
.\tool\build_apk.ps1
.\tool\publish_apk.ps1 -Notes "Stand release"
```

Çıktı (ayrı paketler):

- PWA: `dist\teknofest-pwa-latest.zip` (APK yok)
- APK: `apk\teknofest-yatay-latest.apk` ve `dist\teknofest-yatay-latest.apk`

### 2) Sunucuya koy

Repo + `publish\` + **`apk\teknofest-yatay-latest.apk`** şurada olmalı:

`C:\Users\yturak\Desktop\teknofest-Kiosk`

APK git’te yoktur; `apk\` klasörünü bu PC’den kopyalayın. PWA zip APK içermez.

```powershell
.\tool\copy_publish.ps1 `
  -PublishDir ".\publish" `
  -IisPhysicalPath "\\SUNUCU\C$\Users\yturak\Desktop\teknofest-Kiosk\publish"
.\tool\copy_apk.ps1 -SourceRoot "\\SUNUCU\C$\Users\yturak\Desktop\teknofest-Kiosk"
```

### 3) Sunucu — Flutter yok (Administrator PowerShell)

Tek satır. Birden fazla satır yapıştırmayın (`>>` health’i pull’dan önce çalıştırır).

```powershell
cd C:\Users\yturak\Desktop\teknofest-Kiosk; git pull --ff-only origin main; .\tool\server_up.ps1 -SkipGitPull
```

`server_up.ps1` Desktop parent ACL (IIS 500.19 / 0x80070005), `/teknofest` kaydı ve yerel health yapar.

`-SiteName "<mevcut site adi>"` yazmayın. Script binding’den (`testapp.limak.com.tr`)
veya EnduransStaff/LTStaff uygulamasından siteyi kendi bulur.

Yalnızca gerçek ad vermek isterseniz `iis_inspect.ps1` çıktısındaki **Name**:

```powershell
.\tool\iis_register_application.ps1 -SiteName "Default Web Site"
```

### 4) Health check

Bu IIS sunucusundan `https://testapp.limak.com.tr` genelde timeout verir (nginx/hairpin).
Yerel kontrol:

```powershell
.\tool\health_check.ps1 -LocalOnly
```

500.19 `0x80070005` / insufficient permissions: IIS AppPool `C:\Users\yturak\Desktop` üstünden geçemez. `server_up.ps1` parent klasörlere this-folder-only RX verir; `publish\` ve `web.config` RX/R alır. Site `web.config`’ine Teknofest kuralı yapıştırmayın.

Dışarıdan (bu PC / internet):

```powershell
curl.exe -I https://testapp.limak.com.tr/teknofest
curl.exe -I https://testapp.limak.com.tr/teknofest/app/version.json
curl.exe -I https://testapp.limak.com.tr/teknofest/app/downloads/teknofest-yatay-latest.apk
```

Public 404 ise nginx `/teknofest` isteğini IIS application’a iletmelidir.

## Directory Structure

```
C:\Users\yturak\Desktop\teknofest-Kiosk\
  publish\                                PWA (IIS /teknofest)
    web.config, index.html, assets\
    app\version.json
    app\downloads\                        kopya hedefi; kaynak degil
  apk\teknofest-yatay-latest.apk          APK artifact (PWA zip'te yok)
  dist\teknofest-pwa-latest.zip
  dist\teknofest-yatay-latest.apk
  tool\
    package_release.ps1                   PWA zip
    package_apk.ps1 / copy_apk.ps1        APK
    copy_publish.ps1 / deploy.ps1
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
| curl 28 / timeout | IIS kutusundan public hostname açılmaz; `health_check.ps1 -LocalOnly` |
| PWA HTTP 500.19 `0x80070005` | Desktop ACL; `server_up.ps1` parent traverse + publish RX |
| PWA HTTP 500.19 duplicate | site rewrite mirası; `publish\web.config` `<clear />` |
| Parent node has no children | `-SiteName "<mevcut site adi>"` literal; `iis_inspect.ps1` kullanın |
| 401.3 / boş site | aynı ACL; `server_up.ps1` |
| APK 404 | `apk\teknofest-yatay-latest.apk` kopyalanmadı; PWA zip APK taşımaz |
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
.\tool\deploy.ps1 -SkipPwaBuild -FromZip ".\dist\teknofest-pwa-<onceki>.zip"
.\tool\copy_apk.ps1
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
