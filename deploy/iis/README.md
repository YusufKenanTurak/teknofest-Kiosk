# IIS notes for testapp.limak.com.tr /teknofest

## Host layout

Flutter SDK lives only on the developer PC. On the IIS host the checkout is:

`C:\Users\yturak\Desktop\teknofest-Kiosk`

`/teknofest` physical path is **only** `publish\`:

`C:\Users\yturak\Desktop\teknofest-Kiosk\publish`

Do not point IIS at the repo root (`lib\`, `tool\` must not be served). Do not
use `C:\inetpub\wwwroot`. `deploy.ps1` requires `-SkipPwaBuild` and never
compiles.

Desktop is a user profile path. `iis_register_application.ps1` grants
`IIS_IUSRS`, `IUSR`, and the site app pool RX on `publish\`.

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

## Register (once, on the IIS host)

```powershell
Import-Module WebAdministration
Get-Website
Get-WebApplication
Get-WebBinding

cd C:\Users\yturak\Desktop\teknofest-Kiosk
.\tool\deploy.ps1 -SkipPwaBuild
.\tool\iis_register_application.ps1 -SiteName "<existing site name>"
```

If `/teknofest` was previously registered under `inetpub`, the same command
updates the application physical path to `publish\` on the Desktop checkout.

## Optional site-level fragment

Only use `site-web.config.fragment.xml` if you cannot create an IIS Application and must keep files as a plain folder. Even then: **insert the named Teknofest rules; do not replace the file.**
