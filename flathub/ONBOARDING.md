# Flathub onboarding checklist

App ID: `com.azevedomedia.NitroCam`

1. GitHub account that can open PRs to [flathub/flathub](https://github.com/flathub/flathub).
2. Follow [Flathub App Submission](https://docs.flathub.org/docs/for-app-authors/submission) — request a new app repository via the bot.
3. Confirm legal OK on `LICENSE.flathub` (proprietary + Flatpak redistribution grant).
4. Publish screenshot so AppStream URL resolves:
   `https://nitrocam.app/screenshots/linux-overview.png`
   (file is in `website/public/screenshots/` — deploy the website).
5. Public Linux source: [azevedomedia0/NitroCam-Linux](https://github.com/azevedomedia0/NitroCam-Linux).
   Prefer a Flathub-ready manifest from `com.azevedomedia.NitroCam.yaml.SOURCE_BUILD.example`
   (git tag **or** `extra-data` tarball with sha256). Local `com.azevedomedia.NitroCam.json` is for developer builds only.
6. After the app repo exists, open the submission PR and paste the summary from `SUBMISSION.md`.
7. When live, website download already points at:
   `https://flathub.org/apps/com.azevedomedia.NitroCam`

`gh` CLI is not required on this machine; use the GitHub web UI if preferred.
