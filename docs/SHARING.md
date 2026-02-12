# Sharing HoldSpeak

## Quick Share (no Apple Developer account needed)

```bash
./scripts/package-for-friend.sh
```

This generates `dist/HoldSpeak-friend.zip` containing:
- `HoldSpeak.app` (with WhisperKit model if available)
- `INSTALL.md` (setup guide)

Send the ZIP via AirDrop, iCloud Drive, Google Drive, or any file sharing service.

## What to Tell Your Friend

> "HoldSpeak is a speech-to-text app that runs in your menu bar. It transcribes locally on your Mac — no account or API key needed. Just install, grant 3 permissions (Mic, Input Monitoring, Accessibility), and hold Ctrl+Opt+Space to dictate."

## Gatekeeper Workaround

Since the app is not notarized, your friend will see a Gatekeeper warning. The fix:

1. Right-click `HoldSpeak.app` → **Open** → **Open**
2. If that doesn't work: System Settings → Privacy & Security → scroll down → "Open Anyway"
3. Nuclear option (Terminal): `xattr -dr com.apple.quarantine /Applications/HoldSpeak.app`

## Recommended: Signed + Notarized Build

For the smoothest experience (no Gatekeeper warnings, permissions persist across updates), use a Developer ID signed and notarized build:

```bash
SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/build-macos-app.sh
```

Then notarize with `xcrun notarytool`.

## Bundle Size

The app bundle includes the WhisperKit model (~170 MB). Total ZIP is typically under 200 MB.
