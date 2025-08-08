#!/bin/bash

# Variables
APP_NAME="Cursor"
APPIMAGE_SRC="$HOME/Downloads/Cursor.AppImage"  # change if different
SVG_SRC="$HOME/cursor.svg"

APP_DIR="$HOME/Applications"
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
DESKTOP_FILE="$HOME/.local/share/applications/cursor.desktop"

# Create directories
mkdir -p "$APP_DIR" "$ICON_DIR" "$(dirname "$DESKTOP_FILE")"

# Move AppImage
if [ -f "$APPIMAGE_SRC" ]; then
    mv "$APPIMAGE_SRC" "$APP_DIR/$APP_NAME.AppImage"
fi

# Move SVG icon
if [ -f "$SVG_SRC" ]; then
    mv "$SVG_SRC" "$ICON_DIR/cursor.svg"
fi

# Make AppImage executable
chmod +x "$APP_DIR/$APP_NAME.AppImage"

# Create .desktop file
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=$APP_NAME
Comment=$APP_NAME AI Code Editor
Exec=sh -c "\$HOME/Applications/$APP_NAME.AppImage"
Icon=cursor
Terminal=false
Categories=Development;IDE;
StartupWMClass=$APP_NAME
EOF

# Make .desktop executable
chmod +x "$DESKTOP_FILE"

# Refresh icon and desktop databases
update-icon-caches "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true

echo "✅ $APP_NAME installed and added to launcher"

