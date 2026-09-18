# IIS notes for testapp.limak.com.tr /teknofest

## Host layout

Flutter SDK lives only on the developer PC. On the IIS host the checkout is:

`C:\Users\yturak\Desktop\teknofest-Kiosk`

`/teknofest` physical path is **only** `publish\`:

`C:\Users\yturak\Desktop\teknofest-Kiosk\publish`

Do not point IIS at the repo root (`lib\`, `tool\` must not be served). Do not
use `C:\inetpub\wwwroot`. `deploy.ps1` requires `-SkipPwaBuild` and never
compiles.

PWA (`publish\`) and APK (`apk\teknofest-yatay-latest.apk`) are separate
artifacts. The live download URL is still
`/teknofest/app/downloads/teknofest-yatay-latest.apk` after `copy_apk.ps1`.

Desktop is a user profile path. IIS ApplicationPoolIdentity cannot traverse
`C:\Users\yturak` / `Desktop` unless given this-folder-only RX. That is
500.19 `0x80070005` (cannot read `web.config`). `server_up.ps1` / `Grant-TeknofestIisReadAccess`
grants traverse on those parents, then `(OI)(CI)RX` on `publish\`.

## Do not edit the site-level rewrite map

The existing site `web.config` already routes:

- EnduransStaff
- LTStaff
- ANKStaff
- testcontainer
- Docker Test Container
- staff.enduransteknoloji.com

Those rules must stay untouched.

Teknofest is isolated as an **IIS Application** named `teknofest` under the existing site. Its own `publish/web.config` is used. Match URLs in that file are relative to `/teknofest`, so they cannot capture `LTStaff` or `testcontainer`.

## Register (once, Administrator PowerShell on the IIS host)

```powershell
cd C:\Users\yturak\Desktop\teknofest-Kiosk; git pull --ff-only origin main; .\tool\server_up.ps1 -SkipGitPull
```

Do **not** paste several lines (PowerShell `>>` runs `health_check` before `git pull`).
Do **not** pass `-SiteName "<mevcut site adi>"`.

This host often cannot connect to `https://testapp.limak.com.tr` (curl 28).
`server_up.ps1` health-checks `127.0.0.1` with the site Host header.

If `/teknofest` was previously registered under `inetpub`, the same command
updates the application physical path to `publish\` on the Desktop checkout.

## Optional site-level fragment

Only use `site-web.config.fragment.xml` if you cannot create an IIS Application and must keep files as a plain folder. Even then: **insert the named Teknofest rules; do not replace the file.**
