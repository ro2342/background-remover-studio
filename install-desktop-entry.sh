#!/usr/bin/env bash
# Instala o atalho do Background Remover Studio no menu do sistema (GNOME/KDE/XFCE).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ICON_SRC="$SCRIPT_DIR/src/icon.png"
APPS_DIR="$HOME/.local/share/applications"
ICONS_DIR="$HOME/.local/share/icons/hicolor/256x256/apps"
DESKTOP_DEST="$APPS_DIR/background-remover-studio.desktop"

mkdir -p "$APPS_DIR" "$ICONS_DIR"

# Instala o ícone
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "$ICONS_DIR/background-remover-studio.png"
    ICON_NAME="background-remover-studio"
else
    ICON_NAME="image-x-generic"
fi

# Descobre Python do venv ou do sistema
VENV_PY="$SCRIPT_DIR/.venv/bin/python"
if [ -f "$VENV_PY" ]; then
    PY="$VENV_PY"
else
    PY="$(command -v python3 || command -v python)"
fi

MAIN_PY="$SCRIPT_DIR/src/main.py"

# Gera o .desktop com caminhos absolutos
cat > "$DESKTOP_DEST" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Background Remover Studio
GenericName=Background Remover
Comment=Free local background remover — no uploads, no account, no limits
Exec=$PY $MAIN_PY
Icon=$ICON_NAME
Path=$SCRIPT_DIR/src
Terminal=false
Categories=Graphics;Photography;2DGraphics;RasterGraphics;
Keywords=background;remover;transparent;png;cutout;rembg;
StartupNotify=true
EOF

chmod +x "$DESKTOP_DEST"

# Atualiza o banco de dados de apps (best-effort)
command -v update-desktop-database &>/dev/null && \
    update-desktop-database "$APPS_DIR" 2>/dev/null || true

command -v gtk-update-icon-cache &>/dev/null && \
    gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

echo "✓ Atalho instalado em $DESKTOP_DEST"
echo "  O app deve aparecer no menu do GNOME/KDE em instantes."
