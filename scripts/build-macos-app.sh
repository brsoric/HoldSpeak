#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
APP_NAME="HoldSpeak"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS}/MacOS"
RESOURCES_DIR="${CONTENTS}/Resources"

# Optional overrides (recommended for stable permissions):
#   BUNDLE_ID="com.holdspeak.app"
#   SIGNING_IDENTITY="Apple Development: Your Name (TEAMID)"  (or "Developer ID Application: ...")
BUNDLE_ID="${BUNDLE_ID:-com.holdspeak.app}"
SIGNING_IDENTITY="${SIGNING_IDENTITY:-}"
WHISPER_MODEL="${WHISPER_MODEL:-openai_whisper-small}"

mkdir -p "${BUILD_DIR}"

SCRATCH="/tmp/swift-build"
HOME_DIR="/tmp/codex-home"
mkdir -p "${SCRATCH}" "${HOME_DIR}"

echo "Building SwiftPM product: TranscribeHoldPasteApp"
(
  cd "${ROOT_DIR}"
  HOME="${HOME_DIR}" swift build \
    --product TranscribeHoldPasteApp \
    --scratch-path "${SCRATCH}" \
    --disable-sandbox
)

BIN_PATH="$(cd "${ROOT_DIR}" && HOME="${HOME_DIR}" swift build --show-bin-path --scratch-path "${SCRATCH}" --disable-sandbox)"
BIN="${BIN_PATH}/TranscribeHoldPasteApp"

if [[ ! -f "${BIN}" ]]; then
  echo "Expected binary not found: ${BIN}" >&2
  exit 1
fi

echo "Assembling app bundle: ${APP_BUNDLE}"
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

cp "${ROOT_DIR}/app/Info.plist" "${CONTENTS}/Info.plist"
cp "${BIN}" "${MACOS_DIR}/${APP_NAME}"
chmod +x "${MACOS_DIR}/${APP_NAME}"

if command -v /usr/libexec/PlistBuddy >/dev/null 2>&1; then
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${BUNDLE_ID}" "${CONTENTS}/Info.plist" >/dev/null 2>&1 || true
fi

# Bundle WhisperKit model into Resources
MODEL_DEST="${RESOURCES_DIR}/${WHISPER_MODEL}"
HUGGINGFACE_CACHE="${HOME}/.cache/huggingface/hub"
MODEL_REPO_DIR="${HUGGINGFACE_CACHE}/models--argmaxinc--whisperkit-coreml"

if [[ -d "${ROOT_DIR}/models/${WHISPER_MODEL}" ]]; then
  echo "Bundling WhisperKit model from local models/ directory…"
  cp -R "${ROOT_DIR}/models/${WHISPER_MODEL}" "${MODEL_DEST}"
elif [[ -d "${MODEL_REPO_DIR}" ]]; then
  echo "Bundling WhisperKit model from HuggingFace cache…"
  # Find the model snapshot directory
  SNAPSHOT_DIR=$(find "${MODEL_REPO_DIR}/snapshots" -maxdepth 2 -type d -name "${WHISPER_MODEL}" 2>/dev/null | head -1)
  if [[ -n "${SNAPSHOT_DIR}" && -d "${SNAPSHOT_DIR}" ]]; then
    cp -R "${SNAPSHOT_DIR}" "${MODEL_DEST}"
  else
    echo "Warning: Model '${WHISPER_MODEL}' not found in HuggingFace cache snapshots."
    echo "The app will download the model on first launch."
  fi
else
  echo "Warning: WhisperKit model not found locally."
  echo "To bundle the model, either:"
  echo "  1. Place it in ${ROOT_DIR}/models/${WHISPER_MODEL}/"
  echo "  2. Run the app once to populate the HuggingFace cache"
  echo "The app will download the model on first launch (~170 MB)."
fi

if [[ -d "${MODEL_DEST}" ]]; then
  MODEL_SIZE=$(du -sh "${MODEL_DEST}" | cut -f1)
  echo "Model bundled: ${MODEL_DEST} (${MODEL_SIZE})"
fi

if [[ -f "${ROOT_DIR}/app/icon-source.png" ]]; then
  echo "Building app icon…"
  "${ROOT_DIR}/scripts/build-app-icon.sh" "${ROOT_DIR}/app/icon-source.png" "${RESOURCES_DIR}/AppIcon.icns"
fi

if command -v codesign >/dev/null 2>&1; then
  if [[ -n "${SIGNING_IDENTITY}" ]]; then
    echo "Signing with identity: ${SIGNING_IDENTITY}"
    codesign --force --deep --sign "${SIGNING_IDENTITY}" "${APP_BUNDLE}"
  else
    echo "Ad-hoc signing… (note: ad-hoc signatures often cause macOS permissions to be re-requested after rebuilds)"
    codesign --force --deep --sign - "${APP_BUNDLE}" || true
  fi
fi

BUNDLE_SIZE=$(du -sh "${APP_BUNDLE}" | cut -f1)
echo "Done. Bundle size: ${BUNDLE_SIZE}"
echo "Run: open \"${APP_BUNDLE}\""
