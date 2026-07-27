#!/usr/bin/env bash
#
# Build → sign (Developer ID) → notarize → staple → package a drag-to-install DMG.
#
# ONE-TIME SETUP (see README "Releasing" for details):
#   1. In Xcode: Settings ▸ Accounts ▸ Manage Certificates ▸ + ▸ "Developer ID Application".
#   2. Create an app-specific password at https://appleid.apple.com (Sign-In & Security).
#   3. Store notarization credentials once:
#        xcrun notarytool store-credentials notary-profile \
#          --apple-id "you@example.com" --team-id "YOURTEAMID" --password "app-specific-pw"
#
# Then just run:  ./scripts/release.sh
#
set -euo pipefail

PROJECT="Floating Claude Usage Tracker.xcodeproj"
SCHEME="Floating Claude Usage Tracker"
APP_NAME="Floating Claude Usage Tracker"
NOTARY_PROFILE="${NOTARY_PROFILE:-notary-profile}"

BUILD_DIR="build"
ARCHIVE="$BUILD_DIR/$APP_NAME.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"
STAGE_DIR="$BUILD_DIR/dmg"
APP="$EXPORT_DIR/$APP_NAME.app"
DMG="$BUILD_DIR/$APP_NAME.dmg"

cd "$(dirname "$0")/.."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Finding your Developer ID Application certificate…"
IDENTITY=$(security find-identity -v -p codesigning \
  | grep "Developer ID Application" | head -1 | sed -E 's/.*"(.*)"/\1/')
if [[ -z "${IDENTITY:-}" ]]; then
  echo "ERROR: No 'Developer ID Application' certificate in your keychain." >&2
  echo "Create one: Xcode ▸ Settings ▸ Accounts ▸ Manage Certificates ▸ + ▸ Developer ID Application." >&2
  exit 1
fi
TEAM_ID=$(echo "$IDENTITY" | sed -E 's/.*\(([A-Z0-9]+)\)$/\1/')
echo "    $IDENTITY (team $TEAM_ID)"

echo "==> Archiving (Release)…"
xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration Release \
  -archivePath "$ARCHIVE" archive \
  CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$TEAM_ID" | tail -3

echo "==> Exporting with Developer ID…"
cat > "$BUILD_DIR/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>developer-id</string>
  <key>teamID</key><string>$TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
</dict>
</plist>
PLIST
xcodebuild -exportArchive -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
  -exportPath "$EXPORT_DIR" | tail -3

echo "==> Notarizing the app…"
ditto -c -k --keepParent "$APP" "$BUILD_DIR/$APP_NAME.zip"
xcrun notarytool submit "$BUILD_DIR/$APP_NAME.zip" \
  --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"

echo "==> Building the DMG…"
rm -rf "$STAGE_DIR"; mkdir -p "$STAGE_DIR"
cp -R "$APP" "$STAGE_DIR/"
ln -s /Applications "$STAGE_DIR/Applications"
rm -f "$DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE_DIR" -ov -format UDZO "$DMG" >/dev/null

echo "==> Signing & notarizing the DMG…"
codesign --sign "$IDENTITY" --timestamp "$DMG"
xcrun notarytool submit "$DMG" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$DMG"

echo ""
echo "✅ Done: $DMG"
echo "   Upload it to a GitHub Release, e.g.:"
echo "   gh release create vX.Y.Z \"$DMG\" --title \"vX.Y.Z\" --notes \"…\""
