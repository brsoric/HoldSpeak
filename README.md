# HoldSpeak

A macOS menu bar app for speech-to-text. Hold a hotkey, speak, release — your words are transcribed locally and pasted into the focused text field.

## Features

- **Local transcription** via [WhisperKit](https://github.com/argmaxinc/WhisperKit) — no audio leaves your machine
- **AI rewriting** (optional) — rewrite/polish transcripts before pasting
- **Dual AI provider support** — choose between OpenAI or Google Gemini
- **Configurable hotkeys** — customize key combos in Settings
- **Transcript history** — last 10 transcriptions stored locally
- **Menu bar app** — lives in your menu bar, shows waveform while recording

## Default Hotkeys

| Hotkey | Action |
|--------|--------|
| `Ctrl + Opt + Space` (hold) | Record → transcribe → paste raw transcript |
| `Ctrl + Opt + Cmd + Space` (hold) | Record → transcribe → AI rewrite → paste result |

Both hotkeys are customizable in Settings > Hotkeys.

## AI Rewriting

AI rewriting requires an API key from one of the supported providers:

| Provider | Default Model | Key format |
|----------|--------------|------------|
| **OpenAI** | `gpt-4.1-nano` | `sk-...` |
| **Gemini** | `gemini-2.0-flash` | `AIza...` |

API keys are stored in the **macOS Keychain**. You can fetch available models from the API in Settings > AI Rewriting.

Without an API key, the prompted hotkey pastes the raw transcript.

## Required Permissions

| Permission | Why |
|------------|-----|
| **Microphone** | Record audio for transcription |
| **Accessibility** | Paste text into the focused app via simulated Cmd+V |
| **Input Monitoring** | Detect global hotkeys |

All three are requested on first use and can be managed in Settings > Permissions.

## Build

```bash
swift build
./scripts/build-macos-app.sh
open ./build/HoldSpeak.app
```

## Install to /Applications

```bash
./scripts/install-to-applications.sh
open /Applications/HoldSpeak.app
```

Installing to `/Applications` helps macOS persist permissions across rebuilds.

## Package for a friend

```bash
./scripts/package-for-friend.sh
```

Creates `dist/HoldSpeak-friend.zip` with the app and install instructions.

## Permissions & Code Signing

macOS ties permissions to the app's **bundle identifier + code signature**. The build script uses ad-hoc signing by default, which may cause macOS to re-prompt after each rebuild.

For stable permissions, use a real signing identity:

```bash
SIGNING_IDENTITY="Developer ID Application: ..." ./scripts/build-macos-app.sh
```

Bundle ID: `com.holdspeak.app`

## Sharing

See [docs/SHARING.md](docs/SHARING.md).
