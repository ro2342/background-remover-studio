#!/usr/bin/env bash
# Background Remover Studio — Linux uninstall
# Abre o assistente de limpeza diretamente na aba de desinstalação.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
SETUP_PY="$SCRIPT_DIR/src/setup_assistant.py"

if [ -f "$VENV_DIR/bin/activate" ]; then
    # shellcheck disable=SC1091
    source "$VENV_DIR/bin/activate"
    exec python "$SETUP_PY" --uninstall "$@"
elif command -v python3 &>/dev/null; then
    exec python3 "$SETUP_PY" --uninstall "$@"
else
    echo "Erro: Python 3 não encontrado. Execute start.sh primeiro para configurar o ambiente."
    exit 1
fi
