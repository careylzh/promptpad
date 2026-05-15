#!/usr/bin/env bash

set -euo pipefail

APP_NAME="PromptPad"
CONFIGURATION="${CONFIGURATION:-release}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${DIST_DIR:-"${ROOT_DIR}/dist"}"
STAGING_DIR="${DIST_DIR}/dmg-staging"
APP_DIR="${STAGING_DIR}/${APP_NAME}.app"
DMG_PATH="${DIST_DIR}/${APP_NAME}.dmg"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-"${ROOT_DIR}/.build/module-cache"}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: DMG packaging requires macOS." >&2
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "error: swift was not found. Install Xcode or the Xcode Command Line Tools." >&2
  exit 1
fi

if ! command -v hdiutil >/dev/null 2>&1; then
  echo "error: hdiutil was not found. It is included with macOS." >&2
  exit 1
fi

echo "Building ${APP_NAME} (${CONFIGURATION})..."
mkdir -p "${CLANG_MODULE_CACHE_PATH}"
swift build --disable-sandbox -c "${CONFIGURATION}"
BUILD_PRODUCTS_DIR="$(swift build --disable-sandbox -c "${CONFIGURATION}" --show-bin-path)"
EXECUTABLE_PATH="${BUILD_PRODUCTS_DIR}/${APP_NAME}"

if [[ ! -x "${EXECUTABLE_PATH}" ]]; then
  echo "error: built executable not found at ${EXECUTABLE_PATH}" >&2
  exit 1
fi

echo "Staging ${APP_NAME}.app..."
rm -rf "${STAGING_DIR}" "${DMG_PATH}"
mkdir -p "${APP_DIR}/Contents/MacOS" "${APP_DIR}/Contents/Resources" "${DIST_DIR}"
cp "${EXECUTABLE_PATH}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_DIR}/Contents/MacOS/${APP_NAME}"

cat >"${APP_DIR}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>com.promptpad.${APP_NAME}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

printf "APPL????" >"${APP_DIR}/Contents/PkgInfo"
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
