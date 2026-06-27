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
IMAGE_HAS_EMBEDDED_CHECKSUM=true
if ! hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGING_DIR}" \
  -ov \
  -format UDZO \
  "${DMG_PATH}" >/dev/null; then
  echo "warning: compressed DMG creation failed; falling back to a hybrid HFS image." >&2
  IMAGE_HAS_EMBEDDED_CHECKSUM=false
  rm -f "${DMG_PATH}"
  hdiutil makehybrid \
    -hfs \
    -hfs-volume-name "${APP_NAME}" \
    -ov \
    -o "${DMG_PATH}" \
    "${STAGING_DIR}" >/dev/null
fi

echo "Validating ${DMG_PATH}..."
if [[ "${IMAGE_HAS_EMBEDDED_CHECKSUM}" == true ]]; then
  hdiutil verify "${DMG_PATH}" >/dev/null
else
  hdiutil checksum -type CRC32 "${DMG_PATH}" >/dev/null
fi

MOUNT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/${APP_NAME}.validate.XXXXXX")"
ATTACHED_DEVICE=""

cleanup() {
  if [[ -n "${ATTACHED_DEVICE}" ]]; then
    hdiutil detach "${ATTACHED_DEVICE}" >/dev/null
  fi
  rmdir "${MOUNT_DIR}" 2>/dev/null || true
}
trap cleanup EXIT

ATTACH_OUTPUT="$(hdiutil attach -nobrowse -readonly -mountpoint "${MOUNT_DIR}" "${DMG_PATH}")"
ATTACHED_DEVICE="$(awk '/^\/dev\// { device = $1 } END { print device }' <<<"${ATTACH_OUTPUT}")"

if [[ -z "${ATTACHED_DEVICE}" ]]; then
  echo "error: unable to identify the mounted DMG device." >&2
  exit 1
fi

MOUNTED_APP="${MOUNT_DIR}/${APP_NAME}.app"
if [[ ! -x "${MOUNTED_APP}/Contents/MacOS/${APP_NAME}" ]]; then
  echo "error: mounted DMG does not contain an executable ${APP_NAME}.app." >&2
  exit 1
fi

if [[ "$(readlink "${MOUNT_DIR}/Applications")" != "/Applications" ]]; then
  echo "error: mounted DMG does not contain the Applications shortcut." >&2
  exit 1
fi

plutil -lint "${MOUNTED_APP}/Contents/Info.plist" >/dev/null
# HFS fallback images expose Finder metadata as extended attributes, so strict
# verification is performed before imaging and normal deep verification here.
codesign --verify --deep --verbose=2 "${MOUNTED_APP}"

cleanup
trap - EXIT

echo "Created ${DMG_PATH}"
