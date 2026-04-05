#!/usr/bin/env bash
# Background Remover Studio — Desinstalador do sistema
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/ro2342/background-remover-studio/main/uninstall-system.sh | bash

set -euo pipefail

RESET="\033[0m"; BOLD="\033[1m"; GREEN="\033[32m"; RED="\033[31m"; DIM="\033[2m"

INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/background-remover-studio"
BIN_LINK="${HOME}/.local/bin/background-remover-studio"
DESKTOP_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/applications/background-remover-studio.desktop"
ICON_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps/background-remover-studio.png"
MODEL_CACHE="${HOME}/.u2net"

echo ""
echo -e "${BOLD}Background Remover Studio — Desinstalador${RESET}"
echo ""

remove() {
    if [ -e "$1" ] || [ -L "$1" ]; then
        rm -rf "$1"
        echo -e "  ${GREEN}✓${RESET} Removido: $1"
    fi
}

remove "$INSTALL_DIR"
remove "$BIN_LINK"
remove "$DESKTOP_FILE"
remove "$ICON_FILE"

if [ -t 1 ]; then
    read -r -p "$(echo -e "  Remover cache do modelo de IA (~170 MB em $MODEL_CACHE)? [s/N] ")" ans
    if [[ "${ans:-N}" =~ ^[SsYy]$ ]]; then
        remove "$MODEL_CACHE"
    fi
fi

command -v update-desktop-database &>/dev/null && \
    update-desktop-database "${XDG_DATA_HOME:-$HOME/.local/share}/applications" 2>/dev/null || true

echo ""
echo -e "${BOLD}${GREEN}Desinstalação concluída.${RESET}"
echo ""
