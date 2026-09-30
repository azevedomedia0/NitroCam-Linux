# Submitting NitroCam to Flathub

App ID: **`com.azevedomedia.NitroCam`**  
Display name: **NitroCam**

## Prerequisites

1. GitHub account with permission to open PRs against [flathub/flathub](https://github.com/flathub/flathub).
2. Request access via Flathub new-app bot / invitation (see [Flathub App Submission](https://docs.flathub.org/docs/for-app-authors/submission)).
3. Confirm `LICENSE.flathub` redistribution grant is acceptable to Azevedo Media legal.
4. Host a public screenshot at the URL in metainfo (or switch to a Flathub-hosted path after first upload):
   `https://nitrocam.app/screenshots/linux-overview.png`
   Local file: `screenshots/linux-overview.png`.

## What Flathub reviewers will require

Current local packaging installs a **prebuilt Flutter Linux bundle**. Flathub prefers:

- A `flatpak-builder` manifest that builds from **public source** or approved **extra-data** download URLs with checksums, **or**
- An open-source dual-license for the Linux receiver.

Public source: [github.com/azevedomedia0/NitroCam-Linux](https://github.com/azevedomedia0/NitroCam-Linux).  
See `com.azevedomedia.NitroCam.yaml.SOURCE_BUILD.example` for a Flutter-from-source sketch.

## Local package (works today)

```bash
export PATH="$HOME/flutter/bin:$PATH"
cd linux_desktop
chmod +x flathub/build.sh
./flathub/build.sh
flatpak run com.azevedomedia.NitroCam
```

## Submission steps

1. Create repo `flathub/com.azevedomedia.NitroCam` via the Flathub new-repo workflow (see `ONBOARDING.md`).
2. Copy into that repo:
   - Flathub-ready manifest from `com.azevedomedia.NitroCam.yaml.SOURCE_BUILD.example` (source or extra-data)
   - `com.azevedomedia.NitroCam.metainfo.xml`
   - `com.azevedomedia.NitroCam.desktop`
   - `icons/…`
   - `LICENSE.flathub`
3. Open the submission PR to `flathub/flathub` (master → new app) or push to the app repo per current docs.
4. Address `flatpak-builder-lint` / AppStream review comments.
5. Website download menu already targets `https://flathub.org/apps/com.azevedomedia.NitroCam` (live after Flathub merge + site deploy of screenshot).

## Suggested PR title / body

**Title:** `Add com.azevedomedia.NitroCam`

```
NitroCam turns an iPhone/Android into a Linux virtual webcam (WebRTC).

- App ID: com.azevedomedia.NitroCam
- License: LicenseRef-proprietary + LICENSE.flathub redistribution grant
- Runtime: org.freedesktop.Platform 25.08
- Host deps (not bundled): v4l2loopback, usbmuxd, adb — see PERMISSIONS.md
```

## Host dependencies (document for users)

See `PERMISSIONS.md`. These are **not** shipped inside the Flatpak (kernel module / host tools).
