# Flatpak permissions (com.azevedomedia.NitroCam)

## finish-args rationale

| Permission | Why |
|------------|-----|
| `--share=network` | WebSocket signaling `:4242`, WebRTC, PCM `:4243` |
| `--share=ipc` + X11/Wayland sockets | GUI |
| `--socket=pulseaudio` | Microphone / system audio path |
| `--device=all` | Write frames to host `v4l2loopback` (`/dev/video*`); USB device nodes |
| `--filesystem=xdg-run/pipewire-0` | PipeWire camera / portal path |
| `--filesystem=/var/run/usbmuxd:ro` | iOS USB via usbmuxd |
| `--talk-name=org.freedesktop.Avahi` | Optional LAN discovery |

`--device=all` is broader than ideal; Flathub reviewers may request a narrower alternative if one becomes available for V4L2 loopback.

## Host packages (not in the Flatpak)

| Package | Purpose |
|---------|---------|
| `v4l2loopback` | Virtual webcam |
| `usbmuxd` / libimobiledevice | iOS USB |
| `adb` | Android USB |

Document these on the Flathub listing / website help page.
