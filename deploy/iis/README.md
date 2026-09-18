# IIS notes for testapp.limak.com.tr /teknofest

## Build machine vs IIS server

Flutter SDK lives only on the developer PC. The IIS host copies a prebuilt
`publish/` tree (or `dist\teknofest-iis-latest.zip`). Do not install Flutter
on the server. `deploy.ps1` requires `-SkipPwaBuild` and never compiles.

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

.\tool\iis_register_application.ps1 `
  -SiteName "<existing site name>" `
  -PhysicalPath "C:\inetpub\wwwroot\teknofest"
```

Physical path must be a **copy of `publish/`** (index.html + app/ + web.config), not the Flutter source tree. Populate it with `copy_publish.ps1` / `deploy.ps1 -SkipPwaBuild` from a zip built on the developer PC.

## Optional site-level fragment

Only use `site-web.config.fragment.xml` if you cannot create an IIS Application and must keep files as a plain folder. Even then: **insert the named Teknofest rules; do not replace the file.**
