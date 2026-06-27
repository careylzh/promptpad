#!/usr/bin/env bash

set -euo pipefail

APP_NAME="PromptPad"
CONFIGURATION="${CONFIGURATION:-release}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${DIST_DIR:-"${ROOT_DIR}/dist"}"
STAGING_DIR="${DIST_DIR}/dmg-staging"
APP_DIR="${STAGING_DIR}/${APP_NAME}.app"
DMG_PATH="${DIST_DIR}/${APP_NAME}.dmg"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: DMG packaging requires macOS." >&2
  exit 1
fi

if ! command -v hdiutil >/dev/null 2>&1; then
  echo "error: hdiutil was not found. It is included with macOS." >&2
  exit 1
fi

echo "Staging ${APP_NAME}.app..."
rm -rf "${STAGING_DIR}" "${DMG_PATH}"
mkdir -p "${STAGING_DIR}" "${DIST_DIR}"
CONFIGURATION="${CONFIGURATION}" DIST_DIR="${DIST_DIR}" APP_OUTPUT_PATH="${APP_DIR}" \
  "${ROOT_DIR}/scripts/build-app.sh"
ln -s /Applications "${STAGING_DIR}/Applications"

echo "Creating ${DMG_PATH}..."
if ! hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}" >/dev/null; then
  echo "warning: compressed DMG creation failed; falling back to a hybrid HFS image." >&2
  rm -f "${DMG_PATH}"
  hdiutil makehybrid \
    -hfs \
    -hfs-volume-name "${APP_NAME}" \
    -ov \
    -o "${DMG_PATH}" \
    "${STAGING_DIR}" >/dev/null
fi

echo "Created ${DMG_PATH}"
