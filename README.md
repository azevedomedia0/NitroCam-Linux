# NitroCam for Linux

Linux desktop receiver for [NitroCam](https://nitrocam.app) — use your iPhone or Android as a virtual webcam (Flatpak: `com.azevedomedia.NitroCam`).

## Build

```bash
export PATH="$HOME/flutter/bin:$PATH"
flutter pub get
flutter build linux --release
./flathub/build.sh   # optional local Flatpak
flatpak run com.azevedomedia.NitroCam
```

## Host dependencies

| Package | Purpose |
|---------|---------|
| `v4l2loopback` | Virtual webcam |
| `usbmuxd` | iOS USB |
| `adb` | Android USB |

## Flathub

See [`flathub/SUBMISSION.md`](flathub/SUBMISSION.md).

## Protocol

WebSocket `:4242`, PCM audio `:4243`, QR `nitrocam://<ip>:4242?pair=…`
