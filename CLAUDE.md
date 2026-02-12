# HoldSpeak

macOS menu bar speech-to-text app. Hold hotkey → speak → release → text pasted.

## Tech Stack
- Swift 6.0, macOS 13+, SwiftUI + AppKit, SPM
- WhisperKit (local transcription)
- OpenAI / Gemini API (optional AI rewriting)

## Project Structure
- `Sources/TranscribeHoldPasteKit/` — Core library (audio, transcription, API clients, hotkeys)
- `Sources/TranscribeHoldPasteApp/` — macOS app (UI, settings, design system)
- `Sources/TranscribeHoldPasteCLI/` — CLI smoke-test harness
- `scripts/` — Build, install, package scripts
- `app/` — Info.plist, icon source

## Build
```bash
swift build
./scripts/build-macos-app.sh
```

## Bundle ID
`com.holdspeak.app`
