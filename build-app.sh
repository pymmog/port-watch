#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="PortWatch"
BUNDLE_ID="xyz.portwatch-vi.menubar"
DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
BIN="$ROOT/.build/release/PortWatch"
ICONSET="$ROOT/Resources/AppIcon.iconset"

copy_to_applications=false
for arg in "$@"; do
  case "$arg" in
    --install) copy_to_applications=true ;;
  esac
done

if [ ! -d "$ICONSET" ]; then
  echo "Icon set missing; generating via scripts/generate_app_icon.py …" >&2
  python3 "$ROOT/scripts/generate_app_icon.py"
fi

echo "Building release binary…"
cd "$ROOT"
swift build -c release --product PortWatch -Xswiftc -file-prefix-map -Xswiftc "$PWD=."

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"
chmod +x "$APP/Contents/MacOS/$APP_NAME"

if [ -f "$ROOT/Resources/appicon-512.png" ]; then
  cp "$ROOT/Resources/appicon-512.png" "$APP/Contents/Resources/appicon-512.png"
fi

if command -v iconutil >/dev/null 2>&1 && [ -d "$ICONSET" ]; then
  iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>$APP_NAME</string>
	<key>CFBundleIdentifier</key>
	<string>$BUNDLE_ID</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>CFBundleName</key>
	<string>$APP_NAME</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>LSMinimumSystemVersion</key>
	<string>14.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
</dict>
</plist>
PLIST

# Ad-hoc sign so launch-at-login and local notifications behave on modern macOS.
codesign --force --deep --sign - "$APP"

echo "Built $APP"
if $copy_to_applications; then
  mkdir -p "$HOME/Applications"
  rm -rf "$HOME/Applications/$APP_NAME.app"
  ditto "$APP" "$HOME/Applications/$APP_NAME.app"
  echo "Copied to $HOME/Applications/$APP_NAME.app"
fi