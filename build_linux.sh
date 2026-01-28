#!/bin/bash

# SimpleDaily Build Script for Linux (.deb)

APP_NAME="simple-daily"
VERSION="1.0.0"
ARCH="amd64"
BUILD_DIR="build/linux/x64/release/bundle"
DEB_DIR="build/deb"
DEB_STRUCT="$DEB_DIR/$APP_NAME-$VERSION-$ARCH"

echo "Building SimpleDaily for Linux..."
flutter build linux --release

echo "Setting up Debian package structure..."
mkdir -p "$DEB_STRUCT/DEBIAN"
mkdir -p "$DEB_STRUCT/usr/opt/$APP_NAME"
mkdir -p "$DEB_STRUCT/usr/share/applications"
mkdir -p "$DEB_STRUCT/usr/share/icons/hicolor/256x256/apps"

# Copy Release Bundle
cp -r "$BUILD_DIR/"* "$DEB_STRUCT/usr/opt/$APP_NAME/"

# Create Control File
cat > "$DEB_STRUCT/DEBIAN/control" << EOL
Package: $APP_NAME
Version: $VERSION
Architecture: $ARCH
Maintainer: Rafael Paez <jugamus@gmail.com>
Installed-Size: $(du -s "$DEB_STRUCT/usr" | cut -f1)
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

# Icon (Assuming one exists, otherwise skip or use placeholder)
# cp assets/logo.png "$DEB_STRUCT/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"

echo "Building .deb package..."
dpkg-deb --build "$DEB_STRUCT" "$DEB_DIR/$APP_NAME-$VERSION-$ARCH.deb"

echo "Build Complete: $DEB_DIR/$APP_NAME-$VERSION-$ARCH.deb"
