#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║        Background Remover Studio — Linux Installer          ║
# ║   github.com/ro2342/background-remover-studio               ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/ro2342/background-remover-studio/main/install.sh | bash
#
# Ou baixe e rode localmente:
#   bash install.sh
#
# O que este script faz:
#   1. Detecta sua distro (Fedora, Ubuntu, Debian, Arch)
#   2. Instala dependências do sistema (Python, tkinter, git, clipboard)
#   3. Clona o repositório em ~/.local/share/background-remover-studio
#   4. Cria um ambiente virtual Python isolado
#   5. Instala os pacotes Python (rembg, pillow, numpy, tkinterdnd2)
#   6. Cria atalho no menu do GNOME/KDE/XFCE
#   7. Cria comando `background-remover-studio` no terminal

set -euo pipefail

# ── Cores ────────────────────────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"
DIM="\033[2m"

# ── Configurações ─────────────────────────────────────────────────────────────
REPO_URL="https://github.com/ro2342/background-remover-studio.git"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/background-remover-studio"
BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/256x256/apps"

# ── Helpers ───────────────────────────────────────────────────────────────────
println() { echo -e "$1"; }
step()    { echo -e "\n${BOLD}${BLUE}▶ $1${RESET}"; }
ok()      { echo -e "  ${GREEN}✓${RESET} $1"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
die()     { echo -e "\n${RED}${BOLD}✗ Erro: $1${RESET}\n"; exit 1; }

# ── Banner ────────────────────────────────────────────────────────────────────
println ""
println "${BOLD}╔══════════════════════════════════════════════════╗${RESET}"
println "${BOLD}║   Background Remover Studio — Instalador Linux   ║${RESET}"
println "${BOLD}╚══════════════════════════════════════════════════╝${RESET}"
println "${DIM}  github.com/ro2342/background-remover-studio${RESET}"
println ""

# ── Detecta distro ────────────────────────────────────────────────────────────
step "Detectando sistema..."

DISTRO=""
PKG_MANAGER=""

if command -v dnf &>/dev/null; then
    DISTRO="fedora"
    PKG_MANAGER="dnf"
    ok "Fedora / RHEL / CentOS detectado"
elif command -v apt-get &>/dev/null; then
    DISTRO="debian"
    PKG_MANAGER="apt"
    ok "Ubuntu / Debian detectado"
elif command -v pacman &>/dev/null; then
    DISTRO="arch"
    PKG_MANAGER="pacman"
    ok "Arch Linux detectado"
else
    warn "Distro não reconhecida — tentando continuar assim mesmo"
    DISTRO="unknown"
fi

# Detecta sessão (Wayland vs X11)
SESSION="${XDG_SESSION_TYPE:-}"
if [ -n "${WAYLAND_DISPLAY:-}" ] || [[ "$SESSION" == *wayland* ]]; then
    DISPLAY_SERVER="wayland"
    ok "Sessão Wayland detectada"
else
    DISPLAY_SERVER="x11"
    ok "Sessão X11 detectada"
fi

# ── Instala dependências do sistema ───────────────────────────────────────────
step "Instalando dependências do sistema..."

install_pkg() {
    # $1 = nome do pacote a instalar, $2 = nome legível
    case "$PKG_MANAGER" in
        dnf)    sudo dnf install -y "$1" &>/dev/null ;;
        apt)    sudo apt-get install -y "$1" &>/dev/null ;;
        pacman) sudo pacman -S --noconfirm "$1" &>/dev/null ;;
        *)      warn "Instale manualmente: $2"; return 1 ;;
    esac
}

check_and_install() {
    local cmd="$1" pkg_fedora="$2" pkg_apt="$3" pkg_arch="$4" label="$5"
    if command -v "$cmd" &>/dev/null || python3 -c "import $cmd" &>/dev/null 2>&1; then
        ok "$label já instalado"
        return 0
    fi
    echo -e "  ${DIM}Instalando $label...${RESET}"
    case "$PKG_MANAGER" in
        dnf)    sudo dnf install -y "$pkg_fedora" &>/dev/null && ok "$label instalado" ;;
        apt)    sudo apt-get install -y "$pkg_apt" &>/dev/null && ok "$label instalado" ;;
        pacman) sudo pacman -S --noconfirm "$pkg_arch" &>/dev/null && ok "$label instalado" ;;
        *)      warn "$label não pôde ser instalado automaticamente" ;;
    esac
}

# Python 3.10+
PYTHON=""
for candidate in python3.13 python3.12 python3.11 python3.10 python3; do
    if command -v "$candidate" &>/dev/null; then
        ver=$("$candidate" -c "import sys; print(sys.version_info >= (3,10))" 2>/dev/null || echo "False")
        if [ "$ver" = "True" ]; then
            PYTHON="$candidate"
            break
        fi
    fi
done

if [ -z "$PYTHON" ]; then
    echo -e "  ${DIM}Instalando Python 3...${RESET}"
    case "$PKG_MANAGER" in
        dnf)    sudo dnf install -y python3 &>/dev/null ;;
        apt)    sudo apt-get install -y python3 &>/dev/null ;;
        pacman) sudo pacman -S --noconfirm python &>/dev/null ;;
        *)      die "Python 3.10+ não encontrado. Instale manualmente." ;;
    esac
    PYTHON="python3"
fi
ok "Python: $($PYTHON --version)"

# pip
if ! "$PYTHON" -m pip --version &>/dev/null; then
    echo -e "  ${DIM}Instalando pip...${RESET}"
    case "$PKG_MANAGER" in
        dnf)    sudo dnf install -y python3-pip &>/dev/null ;;
        apt)    sudo apt-get install -y python3-pip &>/dev/null ;;
        pacman) sudo pacman -S --noconfirm python-pip &>/dev/null ;;
    esac
fi
ok "pip instalado"

# tkinter
if ! "$PYTHON" -c "import tkinter" &>/dev/null 2>&1; then
    echo -e "  ${DIM}Instalando tkinter...${RESET}"
    case "$PKG_MANAGER" in
        dnf)    sudo dnf install -y python3-tkinter &>/dev/null ;;
        apt)    sudo apt-get install -y python3-tk &>/dev/null ;;
        pacman) sudo pacman -S --noconfirm tk &>/dev/null ;;
    esac
fi
ok "tkinter instalado"

# git
if ! command -v git &>/dev/null; then
    echo -e "  ${DIM}Instalando git...${RESET}"
    case "$PKG_MANAGER" in
        dnf)    sudo dnf install -y git &>/dev/null ;;
        apt)    sudo apt-get install -y git &>/dev/null ;;
        pacman) sudo pacman -S --noconfirm git &>/dev/null ;;
    esac
fi
ok "git instalado"

# Clipboard
if [ "$DISPLAY_SERVER" = "wayland" ]; then
    if ! command -v wl-copy &>/dev/null; then
        echo -e "  ${DIM}Instalando wl-clipboard (Wayland)...${RESET}"
        case "$PKG_MANAGER" in
            dnf)    sudo dnf install -y wl-clipboard &>/dev/null ;;
            apt)    sudo apt-get install -y wl-clipboard &>/dev/null ;;
            pacman) sudo pacman -S --noconfirm wl-clipboard &>/dev/null ;;
        esac
    fi
    ok "wl-clipboard instalado (copiar imagem para área de transferência)"
else
    if ! command -v xclip &>/dev/null; then
        echo -e "  ${DIM}Instalando xclip (X11)...${RESET}"
        case "$PKG_MANAGER" in
            dnf)    sudo dnf install -y xclip &>/dev/null ;;
            apt)    sudo apt-get install -y xclip &>/dev/null ;;
            pacman) sudo pacman -S --noconfirm xclip &>/dev/null ;;
        esac
    fi
    ok "xclip instalado (copiar imagem para área de transferência)"
fi

# Zenity (seletor de arquivos nativo do GNOME)
if ! command -v zenity &>/dev/null && ! command -v kdialog &>/dev/null; then
    echo -e "  ${DIM}Instalando zenity (seletor de arquivos nativo)...${RESET}"
    case "$PKG_MANAGER" in
        dnf)    sudo dnf install -y zenity &>/dev/null ;;
        apt)    sudo apt-get install -y zenity &>/dev/null ;;
        pacman) sudo pacman -S --noconfirm zenity &>/dev/null ;;
    esac
fi
ok "seletor de arquivos nativo instalado"

# ── Clona ou atualiza o repositório ───────────────────────────────────────────
step "Baixando Background Remover Studio..."

if [ -d "$INSTALL_DIR/.git" ]; then
    warn "Já instalado em $INSTALL_DIR — atualizando..."
    git -C "$INSTALL_DIR" pull --ff-only origin main &>/dev/null
    ok "Atualizado para a versão mais recente"
else
    mkdir -p "$(dirname "$INSTALL_DIR")"
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR" &>/dev/null
    ok "Repositório clonado em $INSTALL_DIR"
fi

# ── Cria ambiente virtual Python ──────────────────────────────────────────────
step "Configurando ambiente Python..."

VENV="$INSTALL_DIR/.venv"
if [ ! -d "$VENV" ]; then
    "$PYTHON" -m venv "$VENV" --system-site-packages &>/dev/null
    ok "Ambiente virtual criado"
else
    ok "Ambiente virtual já existe"
fi

VENV_PY="$VENV/bin/python"
VENV_PIP="$VENV/bin/pip"

# ── Instala pacotes Python ────────────────────────────────────────────────────
step "Instalando pacotes Python (pode demorar alguns minutos na 1ª vez)..."

println "  ${DIM}Atualizando pip...${RESET}"
"$VENV_PIP" install --quiet --upgrade pip

println "  ${DIM}Instalando rembg[cpu], pillow, numpy, tkinterdnd2...${RESET}"
"$VENV_PIP" install --quiet rembg[cpu] pillow numpy tkinterdnd2

ok "Todos os pacotes instalados"

println ""
println "  ${DIM}Nota: na primeira remoção de fundo o modelo de IA (~170 MB)"
println "  será baixado automaticamente. Isso acontece uma única vez.${RESET}"

# ── Cria o ícone ──────────────────────────────────────────────────────────────
step "Instalando ícone e atalho do menu..."

mkdir -p "$ICONS_DIR"
if [ -f "$INSTALL_DIR/src/icon.png" ]; then
    cp "$INSTALL_DIR/src/icon.png" "$ICONS_DIR/background-remover-studio.png"
    ICON_NAME="background-remover-studio"
else
    ICON_NAME="image-x-generic"
fi

# ── Cria entrada .desktop ─────────────────────────────────────────────────────
mkdir -p "$DESKTOP_DIR"
cat > "$DESKTOP_DIR/background-remover-studio.desktop" << DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=Background Remover Studio
GenericName=Background Remover
Comment=Removedor de fundo gratuito e local — sem uploads, sem conta
Exec=$VENV_PY $INSTALL_DIR/src/main.py
Icon=$ICON_NAME
Path=$INSTALL_DIR/src
Terminal=false
Categories=Graphics;Photography;2DGraphics;RasterGraphics;
Keywords=background;remover;transparent;png;cutout;rembg;
StartupNotify=true
DESKTOP
chmod +x "$DESKTOP_DIR/background-remover-studio.desktop"

# Atualiza cache de ícones e apps (best-effort)
command -v update-desktop-database &>/dev/null && \
    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
command -v gtk-update-icon-cache &>/dev/null && \
    gtk-update-icon-cache -f "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

ok "Atalho criado no menu do sistema"

# ── Cria comando no terminal ──────────────────────────────────────────────────
mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/background-remover-studio" << LAUNCHER
#!/usr/bin/env bash
exec "$VENV_PY" "$INSTALL_DIR/src/main.py" "\$@"
LAUNCHER
chmod +x "$BIN_DIR/background-remover-studio"

# Garante que ~/.local/bin está no PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    warn "Adicione ~/.local/bin ao seu PATH para usar o comando no terminal:"
    println "  ${DIM}echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc && source ~/.bashrc${RESET}"
else
    ok "Comando 'background-remover-studio' disponível no terminal"
fi

# ── Concluído ─────────────────────────────────────────────────────────────────
println ""
println "${BOLD}${GREEN}╔══════════════════════════════════════════════════╗${RESET}"
println "${BOLD}${GREEN}║         Instalação concluída com sucesso!        ║${RESET}"
println "${BOLD}${GREEN}╚══════════════════════════════════════════════════╝${RESET}"
println ""
println "  Como abrir o app:"
println ""
println "  ${BOLD}• Menu do sistema${RESET} — procure por 'Background Remover Studio'"
println "  ${BOLD}• Terminal${RESET}        — ${BOLD}background-remover-studio${RESET}"
println "  ${BOLD}• Direto${RESET}          — ${DIM}$VENV_PY $INSTALL_DIR/src/main.py${RESET}"
println ""
println "  Para desinstalar:"
println "  ${DIM}curl -fsSL https://raw.githubusercontent.com/ro2342/background-remover-studio/main/uninstall-system.sh | bash${RESET}"
println ""

# Oferece abrir agora
if [ -t 1 ]; then
    read -r -p "$(echo -e "  ${BOLD}Abrir o app agora? [S/n]${RESET} ")" answer
    answer="${answer:-S}"
    if [[ "$answer" =~ ^[SsYy]$ ]]; then
        println ""
        println "  ${DIM}Iniciando...${RESET}"
        nohup "$VENV_PY" "$INSTALL_DIR/src/main.py" &>/dev/null &
        disown
    fi
fi

println ""
