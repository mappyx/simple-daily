#!/bin/bash

# SimpleDaily Build Script for Linux (.deb & .AppImage)

APP_NAME="simple-daily"
VERSION="1.0.0"
ARCH="amd64"
APPIMAGE_ARCH="x86_64"
BUILD_DIR="build/linux/x64/release/bundle"
DEB_DIR="build/deb"
DEB_STRUCT="$DEB_DIR/$APP_NAME-$VERSION-$ARCH"
APPIMAGE_DIR="build/appimage"
APP_DIR="$APPIMAGE_DIR/AppDir"

# ==========================================
# 0. Locate or Setup Flutter SDK
# ==========================================
FLUTTER_CMD=""

if command -v flutter &> /dev/null; then
  FLUTTER_CMD="flutter"
elif [ -x "$HOME/flutter/bin/flutter" ]; then
  FLUTTER_CMD="$HOME/flutter/bin/flutter"
elif [ -x "$HOME/development/flutter/bin/flutter" ]; then
  FLUTTER_CMD="$HOME/development/flutter/bin/flutter"
elif [ -x "/snap/bin/flutter" ]; then
  FLUTTER_CMD="/snap/bin/flutter"
elif [ -x "build/tools/flutter/bin/flutter" ]; then
  FLUTTER_CMD="build/tools/flutter/bin/flutter"
else
  echo "Flutter not found on system PATH. Setting up temporary Flutter SDK..."
  TOOLS_DIR="build/tools"
  mkdir -p "$TOOLS_DIR"
  
  if command -v git &> /dev/null; then
    echo "Cloning Flutter SDK (stable branch)..."
    git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$TOOLS_DIR/flutter"
  else
    echo "Downloading Flutter SDK tarball..."
    FLUTTER_TAR="$TOOLS_DIR/flutter_linux.tar.xz"
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.27.3-stable.tar.xz"
    if command -v curl &> /dev/null; then
      curl -L "$FLUTTER_URL" -o "$FLUTTER_TAR"
    elif command -v wget &> /dev/null; then
      wget -O "$FLUTTER_TAR" "$FLUTTER_URL"
    else
      echo "Error: Neither git, curl, nor wget found."
      exit 1
    fi
    tar -xf "$FLUTTER_TAR" -C "$TOOLS_DIR"
    rm -f "$FLUTTER_TAR"
  fi
  FLUTTER_CMD="build/tools/flutter/bin/flutter"
fi

FLUTTER_BIN_DIR="$(dirname "$FLUTTER_CMD")"
export PATH="$FLUTTER_BIN_DIR:$PATH"

echo "Using Flutter from: $(which flutter 2>/dev/null || echo "$FLUTTER_CMD")"

echo "Getting Flutter dependencies..."
"$FLUTTER_CMD" pub get

echo "Building SimpleDaily for Linux..."
"$FLUTTER_CMD" build linux --release

if [ ! -d "$BUILD_DIR" ]; then
  echo "Error: Release bundle not found at $BUILD_DIR"
  exit 1
fi

# ==========================================
# 1. Build .deb package (Debian / Ubuntu)
# ==========================================
if command -v dpkg-deb &> /dev/null; then
  echo "Setting up Debian package structure..."
  rm -rf "$DEB_STRUCT"
  mkdir -p "$DEB_STRUCT/DEBIAN"
  mkdir -p "$DEB_STRUCT/usr/opt/$APP_NAME"
  mkdir -p "$DEB_STRUCT/usr/share/applications"
  mkdir -p "$DEB_STRUCT/usr/share/icons/hicolor/256x256/apps"

  # Copy Release Bundle
  cp -r "$BUILD_DIR/"* "$DEB_STRUCT/usr/opt/$APP_NAME/"

  # Copy Icon
  if [ -f "assets/app_icon.png" ]; then
    cp assets/app_icon.png "$DEB_STRUCT/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
  fi

  # Create Control File
  INSTALLED_SIZE=$(du -s "$DEB_STRUCT/usr" | cut -f1)
  cat > "$DEB_STRUCT/DEBIAN/control" << EOL
Package: $APP_NAME
Version: $VERSION
Architecture: $ARCH
Maintainer: Rafael Paez <jugamus@gmail.com>
Installed-Size: $INSTALLED_SIZE
Depends: libgtk-3-0, libx11-6, libblkid1, liblzma5, libnotify4, libayatana-appindicator3-1
Section: utils
Priority: optional
Homepage: https://github.com/mappyx/simple-daily
Description: Simple notes and Kanban project manager.
 A Flutter application for productivity.
EOL

  # Create Desktop Entry
  cat > "$DEB_STRUCT/usr/share/applications/$APP_NAME.desktop" << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=SimpleDaily
Comment=Productivity App
Exec=/usr/opt/$APP_NAME/simple_daily
Icon=$APP_NAME
Categories=Utility;
Terminal=false
EOL

  echo "Building .deb package..."
  dpkg-deb --build "$DEB_STRUCT" "$DEB_DIR/$APP_NAME-$VERSION-$ARCH.deb"
  echo "Debian package created: $DEB_DIR/$APP_NAME-$VERSION-$ARCH.deb"
else
  echo "dpkg-deb not found. Skipping .deb creation."
fi

# ==========================================
# 2. Build .AppImage package (Arch / Fedora / Ubuntu / Universal)
# ==========================================
echo "Setting up AppImage structure..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"
mkdir -p "$APP_DIR/usr/share/applications"
mkdir -p "$APP_DIR/usr/share/icons/hicolor/256x256/apps"

# Copy Release Bundle into AppDir
cp -r "$BUILD_DIR/"* "$APP_DIR/"

# Copy Icon
if [ -f "assets/app_icon.png" ]; then
  cp assets/app_icon.png "$APP_DIR/$APP_NAME.png"
  cp assets/app_icon.png "$APP_DIR/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
fi

# Create Desktop Entry in root and share/applications
cat > "$APP_DIR/$APP_NAME.desktop" << EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=SimpleDaily
Comment=Simple notes and Kanban project manager
Exec=simple_daily
Icon=$APP_NAME
Categories=Utility;
Terminal=false
EOL

cp "$APP_DIR/$APP_NAME.desktop" "$APP_DIR/usr/share/applications/$APP_NAME.desktop"

# Create AppRun launcher
cat > "$APP_DIR/AppRun" << 'EOL'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="$HERE:$PATH"
export LD_LIBRARY_PATH="$HERE/lib:$LD_LIBRARY_PATH"

APP_EXEC="${APPIMAGE:-$HERE/simple_daily}"
DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps"
DESKTOP_FILE="$DESKTOP_DIR/simple-daily.desktop"

# Auto-install desktop entry & icon to system menu on execution
if [ -n "$APPIMAGE" ]; then
  mkdir -p "$DESKTOP_DIR" "$ICON_DIR"
  
  if [ -f "$HERE/simple-daily.png" ]; then
    cp "$HERE/simple-daily.png" "$ICON_DIR/simple-daily.png" 2>/dev/null || true
  fi
  
  if [ ! -f "$DESKTOP_FILE" ] || ! grep -qF "$APP_EXEC" "$DESKTOP_FILE" 2>/dev/null; then
    cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=SimpleDaily
Comment=Simple notes and Kanban project manager
Exec="$APP_EXEC" %U
Icon=simple-daily
Categories=Utility;
Terminal=false
StartupWMClass=simple_daily
EOF
    chmod +x "$DESKTOP_FILE" 2>/dev/null || true
    command -v update-desktop-database &>/dev/null && update-desktop-database "$DESKTOP_DIR" &>/dev/null || true
  fi
fi

exec "$HERE/simple_daily" "$@"
EOL

chmod +x "$APP_DIR/AppRun"

echo "Building universal .AppImage package (FUSE3 / Modern Linux compatible)..."
OUTPUT_APPIMAGE="$APPIMAGE_DIR/SimpleDaily-$VERSION-$APPIMAGE_ARCH.AppImage"
PAYLOAD_TAR="$APPIMAGE_DIR/payload.tar.xz"

# Compress AppDir bundle
tar -cJf "$PAYLOAD_TAR" -C "$APP_DIR" .

# Build self-extracting executable header + payload
cat > "$OUTPUT_APPIMAGE" << 'HEADER_END'
#!/bin/bash
# SimpleDaily Universal Executable (.AppImage)
# Compatible with Arch, Fedora, Ubuntu, Debian (No FUSE2 dependency required)

TMP_DIR="$(mktemp -d /tmp/.simple_daily_appimage_XXXXXX)"
cleanup() {
  rm -rf "$TMP_DIR" 2>/dev/null
}
trap cleanup EXIT INT TERM

# Extract payload
PAYLOAD_LINE=$(grep -a -n '^__PAYLOAD_BELOW__' "$0" | cut -d: -f1)
tail -n +$((PAYLOAD_LINE + 1)) "$0" | tar -xJ -C "$TMP_DIR" 2>/dev/null

export APPIMAGE="$(readlink -f "$0")"
chmod +x "$TMP_DIR/AppRun" "$TMP_DIR/simple_daily" 2>/dev/null
"$TMP_DIR/AppRun" "$@"
exit $?

__PAYLOAD_BELOW__
HEADER_END

# Append binary payload and make executable
cat "$PAYLOAD_TAR" >> "$OUTPUT_APPIMAGE"
rm -f "$PAYLOAD_TAR"
chmod +x "$OUTPUT_APPIMAGE"

if [ -f "$OUTPUT_APPIMAGE" ]; then
  echo "AppImage created successfully: $OUTPUT_APPIMAGE"
else
  echo "Error: Failed to build AppImage."
  exit 1
fi

echo "Build Complete!"

