# HoldSpeak — Install Guide

HoldSpeak is a **menu bar** speech-to-text app for macOS. It runs 100% locally using WhisperKit — no API key needed for basic transcription.

## Install

1. Unzip the download.
2. Drag `HoldSpeak.app` into your `Applications` folder.
3. First launch:
   - Right-click `HoldSpeak.app` → **Open** → **Open**
   - (You may need to repeat this once due to macOS Gatekeeper.)

## Grant Permissions

System Settings → Privacy & Security:

| Permission | Why |
|---|---|
| **Microphone** | Record audio for transcription |
| **Input Monitoring** | Detect global keyboard shortcuts |
| **Accessibility** | Simulate Cmd+V to paste text |

The app will prompt for each permission on first use. You can also grant them in Settings → Permissions tab.

## Use

- Hold **Ctrl + Opt + Space** → speak → release → pastes transcript
- Hold **Ctrl + Opt + Cmd + Space** → speak → release → pastes AI-rewritten text (requires API key)

## Optional: AI Rewriting

To enable prompted mode (AI rewriting), open Settings → AI Rewriting and add an OpenAI API key. Without an API key, prompted mode will paste the raw transcript instead.

- The API key is stored in the **macOS Keychain**.
- You are responsible for any OpenAI API costs.

## Troubleshooting

- **Model loading**: On first launch, the WhisperKit model takes a few seconds to load. Wait for the menu bar icon to stop pulsing.
- **Paste fails**: The app copies to clipboard as fallback. Grant Accessibility permission and try again.
- **Hotkey not working**: Ensure Input Monitoring is granted in System Settings.
- **Gatekeeper blocks app**: Right-click → Open, or run: `xattr -dr com.apple.quarantine /Applications/HoldSpeak.app`
