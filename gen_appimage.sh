#!/usr/bin/env python3
"""Genera AppImage para CachyOS (compatible sin FUSE2)."""
import os, tarfile, stat, io, shutil

BASE = "/home/desarrollo/Documentos/GitHub/simple-daily"
BUNDLE = f"{BASE}/build/linux/x64/release/bundle"
APPIMAGE_DIR = f"{BASE}/build/appimage"
APP_DIR = f"{APPIMAGE_DIR}/AppDir"
VERSION = "1.0.0"
ARCH = "x86_64"

# 1. Clean and create AppDir
print("=== Creando AppDir ===")
if os.path.exists(APP_DIR):
    shutil.rmtree(APP_DIR)
os.makedirs(APP_DIR, exist_ok=True)

usr_share_apps = f"{APP_DIR}/usr/share/applications"
usr_share_icons = f"{APP_DIR}/usr/share/icons/hicolor/256x256/apps"
os.makedirs(usr_share_apps, exist_ok=True)
os.makedirs(usr_share_icons, exist_ok=True)

# 2. Copy release bundle
print("=== Copiando bundle ===")
for item in os.listdir(BUNDLE):
    src = os.path.join(BUNDLE, item)
    dst = os.path.join(APP_DIR, item)
    if os.path.isdir(src):
        shutil.copytree(src, dst, dirs_exist_ok=True)
    else:
        shutil.copy2(src, dst)

# 3. Copy icon
icon_src = f"{BASE}/assets/app_icon.png"
if os.path.exists(icon_src):
    print("=== Copiando icono ===")
    shutil.copy2(icon_src, f"{APP_DIR}/simple-daily.png")
    shutil.copy2(icon_src, f"{usr_share_icons}/simple-daily.png")

# 4. Create desktop entry
print("=== Creando desktop entry ===")
desktop = """[Desktop Entry]
Version=1.0
Type=Application
Name=SimpleDaily
Comment=Simple notes and Kanban project manager
Exec=simple_daily
Icon=simple-daily
Categories=Utility;
Terminal=false
"""
with open(f"{APP_DIR}/simple-daily.desktop", "w") as f:
    f.write(desktop)
with open(f"{usr_share_apps}/simple-daily.desktop", "w") as f:
    f.write(desktop)

# 5. Create AppRun
print("=== Creando AppRun ===")
apprun = r"""#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="$HERE:$PATH"
export LD_LIBRARY_PATH="$HERE/lib:$LD_LIBRARY_PATH"
APP_EXEC="${APPIMAGE:-$HERE/simple_daily}"
DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICON_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps"
DESKTOP_FILE="$DESKTOP_DIR/simple-daily.desktop"

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
"""
with open(f"{APP_DIR}/AppRun", "w") as f:
    f.write(apprun)
os.chmod(f"{APP_DIR}/AppRun", 0o755)
bin_path = f"{APP_DIR}/simple_daily"
if os.path.exists(bin_path):
    os.chmod(bin_path, 0o755)

# 6. Build tar.xz payload
print("=== Generando tar.xz payload ===")
payload = io.BytesIO()
with tarfile.open(fileobj=payload, mode="w:xz") as tar:
    tar.add(APP_DIR, arcname=".")
payload.seek(0)
payload_data = payload.read()

# 7. Build AppImage (self-extracting shell + tar.xz)
print("=== Construyendo AppImage ===")
header = b"""#!/bin/bash
TMP_DIR="$(mktemp -d /tmp/.simple_daily_appimage_XXXXXX)"
cleanup() { rm -rf "$TMP_DIR" 2>/dev/null; }
trap cleanup EXIT INT TERM
PAYLOAD_LINE=$(grep -a -n '^__PAYLOAD_BELOW__' "$0" | cut -d: -f1)
tail -n +$((PAYLOAD_LINE + 1)) "$0" | tar -xJ -C "$TMP_DIR" 2>/dev/null
export APPIMAGE="$(readlink -f "$0")"
chmod +x "$TMP_DIR/AppRun" "$TMP_DIR/simple_daily" 2>/dev/null
"$TMP_DIR/AppRun" "$@"
exit $?

__PAYLOAD_BELOW__
"""

os.makedirs(APPIMAGE_DIR, exist_ok=True)
output_path = f"{APPIMAGE_DIR}/SimpleDaily-{VERSION}-{ARCH}.AppImage"
with open(output_path, "wb") as f:
    f.write(header)
    f.write(payload_data)

os.chmod(output_path, 0o755)
size_mb = os.path.getsize(output_path) / (1024 * 1024)
print(f"\n=== ¡AppImage generado! ===")
print(f"  Ruta: {output_path}")
print(f"  Tamaño: {size_mb:.1f} MB")
print(f"\nPara usar en CachyOS:")
print(f"  chmod +x {output_path}")
print(f"  ./{output_path}")