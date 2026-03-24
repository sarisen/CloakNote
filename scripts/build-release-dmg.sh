#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="${PROJECT_PATH:-$ROOT_DIR/CloakNote.xcodeproj}"
SCHEME="${SCHEME:-CloakNote}"
APP_NAME="${APP_NAME:-CloakNote}"
BUILD_ROOT="${BUILD_ROOT:-$ROOT_DIR/build/release}"
DERIVED_DATA_PATH="$BUILD_ROOT/DerivedData"
STAGING_DIR="$BUILD_ROOT/staging"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/$APP_NAME.app"
VERSION="${VERSION:-${GITHUB_REF_NAME:-dev}}"
VERSION="${VERSION#refs/tags/}"
OUTPUT_NAME="${OUTPUT_NAME:-$APP_NAME-$VERSION.dmg}"
OUTPUT_PATH="${OUTPUT_PATH:-$BUILD_ROOT/$OUTPUT_NAME}"

rm -rf "$DERIVED_DATA_PATH" "$STAGING_DIR" "$OUTPUT_PATH"
mkdir -p "$BUILD_ROOT" "$STAGING_DIR"

xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -destination "generic/platform=macOS" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  clean build

cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$OUTPUT_PATH"

echo "Created DMG at $OUTPUT_PATH"
