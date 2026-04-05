#!/usr/bin/env bash
# Background Remover Studio — Linux launcher
# Substitui o start.bat original para Fedora/Ubuntu/Debian e derivados.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
SETUP_PY="$SCRIPT_DIR/src/setup_assistant.py"

# ── 1. Garante que Python 3.10+ está disponível ──────────────────────────────
check_python() {
    local py=""
    for candidate in python3 python; do
        if command -v "$candidate" &>/dev/null; then
            local ver
            ver=$("$candidate" -c "import sys; print(sys.version_info >= (3,10))" 2>/dev/null || echo "False")
            if [ "$ver" = "True" ]; then
                py="$candidate"
                break
            fi
        fi
    done
    echo "$py"
}

PY=$(check_python)

if [ -z "$PY" ]; then
    # Tenta instalar Python via dnf (Fedora) ou apt (Debian/Ubuntu)
    echo "Python 3.10+ não encontrado. Tentando instalar..."
    if command -v dnf &>/dev/null; then
        sudo dnf install -y python3 python3-pip python3-tkinter
    elif command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y python3 python3-pip python3-tk
    else
        echo "Erro: instale Python 3.10+ manualmente e tente novamente."
        exit 1
    fi
    PY=$(check_python)
fi

if [ -z "$PY" ]; then
    echo "Erro: Python 3.10+ não encontrado após tentativa de instalação."
    exit 1
fi

# ── 2. Verifica tkinter ───────────────────────────────────────────────────────
if ! "$PY" -c "import tkinter" &>/dev/null; then
    echo "tkinter não encontrado. Tentando instalar..."
    if command -v dnf &>/dev/null; then
        sudo dnf install -y python3-tkinter
    elif command -v apt-get &>/dev/null; then
        sudo apt-get install -y python3-tk
    fi
fi

# ── 3. Cria virtualenv se não existir ────────────────────────────────────────
if [ ! -d "$VENV_DIR" ]; then
    echo "Criando ambiente virtual em $VENV_DIR ..."
    "$PY" -m venv "$VENV_DIR" --system-site-packages
fi

# ── 4. Ativa o virtualenv e abre o assistente de setup ───────────────────────
# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

exec python "$SETUP_PY" "$@"
