# Expected flatpak-builder-lint findings for Flathub review

Document these when opening the submission PR / requesting exceptions:

## appid-url-not-reachable

Linter probes `https://azevedomedia.com` from reverse-DNS app ID
`com.azevedomedia.NitroCam`. Public product site is `https://nitrocam.app`
(already in metainfo `<url type="homepage">`). Request an exception or point
azevedomedia.com at nitrocam.app.

## finish-args-host-var-access

`--filesystem=/var/run/usbmuxd:ro` is required for iOS USB via host usbmuxd.
Justify in review; see `PERMISSIONS.md`.

## screenshot-image-not-found

Until the website ships `website/public/screenshots/linux-overview.png`,
`https://nitrocam.app/screenshots/linux-overview.png` 404s. Deploy the site
before Flathub AppStream review.

## Local validation commands

```bash
appstreamcli validate --no-net com.azevedomedia.NitroCam.metainfo.xml
desktop-file-validate com.azevedomedia.NitroCam.desktop
flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest com.azevedomedia.NitroCam.json
```
