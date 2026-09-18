# IIS notes for testapp.limak.com.tr /teknofest

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

## Register

```powershell
Import-Module WebAdministration
Get-Website
Get-WebApplication
Get-WebBinding

.\tool\iis_register_application.ps1 `
  -SiteName "<existing site name>" `
  -PhysicalPath "C:\inetpub\wwwroot\teknofest"
```

Physical path must be a **copy of `publish/`** (index.html + app/ + web.config), not the Flutter source tree.

## Optional site-level fragment

Only use `site-web.config.fragment.xml` if you cannot create an IIS Application and must keep files as a plain folder. Even then: **insert the named Teknofest rules; do not replace the file.**
