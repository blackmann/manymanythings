#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"
PROJECT="$PROJECT_DIR/manymanythings.xcodeproj"
PBXPROJ="$PROJECT/project.pbxproj"
SCHEME="manymanythings"
EXPORT_OPTS="$PROJECT_DIR/build/ExportOptions.plist"
APPCAST="$SCRIPT_DIR/../website/public/appcast.xml"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/manymanythings.xcarchive"
EXPORT_PATH="$BUILD_DIR/export"
APP_PATH="$EXPORT_PATH/manymanythings.app"
ZIP_PATH="$BUILD_DIR/manymanythings.zip"

# --- Read current version and build number from project.pbxproj ---

current_version=$(grep -m1 'MARKETING_VERSION' "$PBXPROJ" | sed 's/.*= *//;s/ *;.*//')
current_build=$(grep -m1 'CURRENT_PROJECT_VERSION' "$PBXPROJ" | sed 's/.*= *//;s/ *;.*//')
next_build=$((current_build + 1))

echo "Current version: $current_version (build $current_build)"
echo ""

# --- Prompt for version and build number ---

read -p "Version [$current_version]: " version
version="${version:-$current_version}"

read -p "Build number [$next_build]: " build
build="${build:-$next_build}"

echo ""
echo "Will release: v$version (build $build)"
read -p "Continue? [Y/n] " confirm
if [[ "${confirm:-Y}" =~ ^[Nn] ]]; then
    echo "Aborted."
    exit 0
fi

# --- Update version in project.pbxproj ---

echo ""
echo "==> Updating version in project.pbxproj..."
sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $version;/g" "$PBXPROJ"
sed -i '' "s/CURRENT_PROJECT_VERSION = .*;/CURRENT_PROJECT_VERSION = $build;/g" "$PBXPROJ"
echo "    MARKETING_VERSION = $version"
echo "    CURRENT_PROJECT_VERSION = $build"

# --- Clean build directory ---

rm -rf "$ARCHIVE_PATH" "$EXPORT_PATH" "$ZIP_PATH"
mkdir -p "$BUILD_DIR"

# --- Step 1: Archive ---

echo ""
echo "==> Archiving..."
xcodebuild archive \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -archivePath "$ARCHIVE_PATH" \
    -quiet

echo "    Archive created at $ARCHIVE_PATH"

# --- Step 2: Export ---

echo ""
echo "==> Exporting with Developer ID signing..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTS" \
    -exportPath "$EXPORT_PATH" \
    -quiet

echo "    Exported to $EXPORT_PATH"

# --- Step 3: Zip for notarization ---

echo ""
echo "==> Creating zip for notarization..."
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo "    Created $ZIP_PATH"

# --- Step 4: Notarize ---

echo ""
echo "==> Submitting for notarization (this may take a few minutes)..."
xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "notarytool" \
    --wait

# --- Step 5: Staple ---

echo ""
echo "==> Stapling notarization ticket..."
xcrun stapler staple "$APP_PATH"

# Re-zip with stapled app
echo "==> Re-creating zip with stapled app..."
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"
echo "    Created $ZIP_PATH"

# --- Step 6: Sign with Sparkle ---

echo ""
echo "==> Signing with Sparkle's sign_update..."

# Find sign_update from Sparkle in DerivedData
DERIVED_DATA_DIR=$(xcodebuild -project "$PROJECT" -scheme "$SCHEME" -showBuildSettings 2>/dev/null \
    | grep ' BUILD_DIR ' | sed 's/.*= *//' | sed 's|/Build/Products$||')
SIGN_UPDATE=$(find "$DERIVED_DATA_DIR" -name "sign_update" -type f 2>/dev/null | head -1)

if [ -z "$SIGN_UPDATE" ]; then
    echo "ERROR: Could not find Sparkle's sign_update tool in DerivedData."
    echo "Make sure Sparkle is built as part of the project."
    exit 1
fi

SIGN_OUTPUT=$("$SIGN_UPDATE" "$ZIP_PATH")
echo "    sign_update output: $SIGN_OUTPUT"

# Parse edSignature and length
ED_SIGNATURE=$(echo "$SIGN_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')
FILE_LENGTH=$(stat -f%z "$ZIP_PATH")

if [ -z "$ED_SIGNATURE" ]; then
    echo "ERROR: Could not parse edSignature from sign_update output."
    exit 1
fi

echo "    edSignature: $ED_SIGNATURE"
echo "    File size: $FILE_LENGTH bytes"

# --- Step 7: Create GitHub Release ---

echo ""
echo "==> Creating GitHub release v$version..."
gh release create "v$version" "$ZIP_PATH" \
    --title "v$version" \
    --generate-notes
echo "    GitHub release v$version created."

# --- Step 8: Update appcast.xml ---

echo ""
echo "==> Updating appcast.xml..."

PUB_DATE=$(date -R)

cat > "$APPCAST" << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>Many Many Things Changelog</title>
        <link>https://degreat.co.uk/manymanythings/appcast.xml</link>
        <description>Most recent changes with links to updates.</description>
        <language>en</language>
        <item>
            <title>Version $version</title>
            <sparkle:version>$build</sparkle:version>
            <sparkle:shortVersionString>$version</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
            <pubDate>$PUB_DATE</pubDate>
            <enclosure
                url="https://github.com/blackmann/manymanythings/releases/download/v$version/manymanythings.zip"
                length="$FILE_LENGTH"
                type="application/octet-stream"
                sparkle:edSignature="$ED_SIGNATURE"
            />
        </item>
    </channel>
</rss>
EOF

echo "    Updated $APPCAST"

# --- Done ---

echo ""
echo "========================================="
echo "  Release v$version (build $build) ready!"
echo "========================================="
echo ""
echo "Next steps:"
echo "  1. Deploy the updated appcast.xml"
echo "  2. Commit the version bump and appcast changes"
