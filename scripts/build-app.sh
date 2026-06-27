#!/usr/bin/env bash

set -euo pipefail

APP_NAME="PromptPad"
CONFIGURATION="${CONFIGURATION:-release}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${DIST_DIR:-"${ROOT_DIR}/dist"}"
APP_OUTPUT_PATH="${APP_OUTPUT_PATH:-"${DIST_DIR}/${APP_NAME}.app"}"
export CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-"${ROOT_DIR}/.build/module-cache"}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: app bundle creation requires macOS." >&2
  exit 1
fi

if ! command -v swift >/dev/null 2>&1; then
  echo "error: swift was not found. Install Xcode or the Xcode Command Line Tools." >&2
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

echo "Creating locally signed app bundle at ${APP_OUTPUT_PATH}..."
rm -rf "${APP_OUTPUT_PATH}"
mkdir -p "${APP_OUTPUT_PATH}/Contents/MacOS" "${APP_OUTPUT_PATH}/Contents/Resources"
cp "${EXECUTABLE_PATH}" "${APP_OUTPUT_PATH}/Contents/MacOS/${APP_NAME}"
chmod +x "${APP_OUTPUT_PATH}/Contents/MacOS/${APP_NAME}"

cat >"${APP_OUTPUT_PATH}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
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

printf "APPL????" >"${APP_OUTPUT_PATH}/Contents/PkgInfo"
codesign --force --deep --sign - "${APP_OUTPUT_PATH}"

echo "Validating app bundle..."
plutil -lint "${APP_OUTPUT_PATH}/Contents/Info.plist" >/dev/null
codesign --verify --deep --strict --verbose=2 "${APP_OUTPUT_PATH}"

SIGNATURE_DETAILS="$(codesign --display --verbose=2 "${APP_OUTPUT_PATH}" 2>&1)"
if ! grep -q '^Signature=adhoc$' <<<"${SIGNATURE_DETAILS}"; then
  echo "error: expected an ad-hoc signature without a Developer ID certificate." >&2
  exit 1
fi

if ! grep -q '^TeamIdentifier=not set$' <<<"${SIGNATURE_DETAILS}"; then
  echo "error: app bundle unexpectedly contains a development-team identity." >&2
  exit 1
fi

echo "Created locally signed app bundle: ${APP_OUTPUT_PATH}"
