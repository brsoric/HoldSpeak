#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="HoldSpeak"

DIST_DIR="${ROOT_DIR}/dist"
PAYLOAD_DIR="${DIST_DIR}/${APP_NAME}"
ZIP_PATH="${DIST_DIR}/${APP_NAME}-friend.zip"

echo "Building app…"
"${ROOT_DIR}/scripts/build-macos-app.sh"

SRC_APP="${ROOT_DIR}/build/${APP_NAME}.app"
if [[ ! -d "${SRC_APP}" ]]; then
  echo "Missing app bundle: ${SRC_APP}" >&2
  exit 1
fi

rm -rf "${DIST_DIR}"
mkdir -p "${PAYLOAD_DIR}"

echo "Staging payload…"
cp -R "${SRC_APP}" "${PAYLOAD_DIR}/${APP_NAME}.app"
cp "${ROOT_DIR}/docs/FRIEND-INSTALL.md" "${PAYLOAD_DIR}/INSTALL.md"

# Verify key files exist in the bundle
echo "Verifying bundle integrity…"
if [[ ! -f "${PAYLOAD_DIR}/${APP_NAME}.app/Contents/MacOS/${APP_NAME}" ]]; then
  echo "Error: Missing executable in bundle" >&2
  exit 1
fi
if [[ ! -f "${PAYLOAD_DIR}/${APP_NAME}.app/Contents/Info.plist" ]]; then
  echo "Error: Missing Info.plist in bundle" >&2
  exit 1
fi
if [[ -d "${PAYLOAD_DIR}/${APP_NAME}.app/Contents/Resources/openai_whisper-small" ]]; then
  echo "  WhisperKit model: bundled"
else
  echo "  WhisperKit model: NOT bundled (will download on first launch)"
fi

# Avoid shipping quarantine bits from the build machine (download will still be quarantined by the recipient).
/usr/bin/xattr -dr com.apple.quarantine "${PAYLOAD_DIR}/${APP_NAME}.app" 2>/dev/null || true

echo "Creating zip: ${ZIP_PATH}"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent --norsrc "${PAYLOAD_DIR}" "${ZIP_PATH}"

ZIP_SIZE=$(du -sh "${ZIP_PATH}" | cut -f1)
echo "Done."
echo "ZIP size: ${ZIP_SIZE}"
echo "Share: ${ZIP_PATH}"
