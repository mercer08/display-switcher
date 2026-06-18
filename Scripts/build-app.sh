#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Display Switcher"
BUNDLE_ID="dev.local.display-switcher"
APP_DIR="$ROOT_DIR/build/$APP_NAME.app"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"
INSTALLED_APP="$INSTALL_DIR/$APP_NAME.app"
EXECUTABLE="$ROOT_DIR/.build/release/DisplaySwitcher"
VERSION="${APP_VERSION:-0.1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-$(git rev-list --count HEAD 2>/dev/null || echo 1)}"
GIT_COMMIT="$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1 && ! git diff-index --quiet HEAD --; then
  GIT_COMMIT="$GIT_COMMIT-dirty"
fi
BUILD_TIME="$(TZ=Asia/Shanghai date +"%Y-%m-%d %H:%M:%S CST")"

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/DisplaySwitcher"
cp "$ROOT_DIR/Assets/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
cp "$ROOT_DIR/Assets/AppIcon.png" "$APP_DIR/Contents/Resources/AppIcon.png"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>DisplaySwitcher</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$VERSION</string>
  <key>CFBundleVersion</key>
  <string>$BUILD_NUMBER</string>
  <key>DSBuildTime</key>
  <string>$BUILD_TIME</string>
  <key>DSGitCommit</key>
  <string>$GIT_COMMIT</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSSupportsAutomaticGraphicsSwitching</key>
  <true/>
</dict>
</plist>
PLIST

echo "Built: $APP_DIR"
echo "Version: $VERSION ($BUILD_NUMBER)"
echo "Build time: $BUILD_TIME"
echo "Git commit: $GIT_COMMIT"

install_app() {
  rm -rf "$INSTALLED_APP"
  /usr/bin/ditto "$APP_DIR" "$INSTALLED_APP"
}

if [[ "${INSTALL_APP:-1}" == "1" ]]; then
  if [[ -w "$INSTALL_DIR" ]]; then
    install_app
  else
    sudo rm -rf "$INSTALLED_APP"
    sudo /usr/bin/ditto "$APP_DIR" "$INSTALLED_APP"
  fi
  echo "Installed: $INSTALLED_APP"
fi
