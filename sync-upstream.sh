#!/usr/bin/env bash
# sync-upstream.sh — Sincroniza este fork Linux com o repo original do Windows
# e reaplicaa todos os patches Linux automaticamente.
#
# Uso: ./sync-upstream.sh
#
# O que este script faz:
#   1. Faz fetch do repo original (upstream)
#   2. Faz merge dos arquivos atualizados em cima do fork
#   3. Reaaplica os patches Linux (clipboard, iconphoto, etc.)
#   4. Commita e faz push automaticamente

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

UPSTREAM_URL="https://github.com/sabnck/background-remover-studio.git"

echo "🔄  Sincronizando com o upstream..."

# Adiciona o remote upstream se não existir
if ! git remote get-url upstream &>/dev/null; then
    echo "  Adicionando remote upstream..."
    git remote add upstream "$UPSTREAM_URL"
fi

git fetch upstream

# Verifica se há novidades
LOCAL_SHA=$(git rev-parse HEAD)
UPSTREAM_SHA=$(git rev-parse upstream/main)

if [ "$LOCAL_SHA" = "$UPSTREAM_SHA" ]; then
    echo "✓ Já está atualizado com o upstream."
    exit 0
fi

echo "  Novidades encontradas. Fazendo merge..."
git merge upstream/main --no-edit --allow-unrelated-histories || true

echo ""
echo "🔧  Aplicando patches Linux..."

python3 << 'PYEOF'
import re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
BR   = ROOT / "src" / "background_remover.py"
SA   = ROOT / "src" / "setup_assistant.py"
UPD  = ROOT / "src" / "updater.py"
errors = []

# ── background_remover.py ──────────────────────────────────────────────────
br = BR.read_text()

# Se o upstream restaurou o setup_assistant.pyw, renomear
pyw = ROOT / "src" / "setup_assistant.pyw"
if pyw.exists() and not SA.exists():
    pyw.rename(SA)
    print("  Renomeado setup_assistant.pyw → setup_assistant.py")

# ctypes import
if 'import ctypes' in br and 'import shutil' not in br:
    br = br.replace(
        'import threading, os, io, sys\nfrom pathlib import Path\nimport ctypes',
        'import threading, os, io, sys, shutil, subprocess\nfrom pathlib import Path'
    )
    print("  ✓ background_remover.py: ctypes removido")

# clipboard
if 'ctypes.windll' in br:
    old = br[br.find('def copy_image_to_clipboard'):br.find('\ndef prepare_export_image')]
    new = '''def copy_image_to_clipboard(img: Image.Image):
    """Copy image to clipboard. Supports Wayland (wl-copy) and X11 (xclip)."""
    rgba = sanitizar_rgb_transparente(img.convert("RGBA"))
    buf = io.BytesIO()
    rgba.save(buf, "PNG")
    png_data = buf.getvalue()

    session = os.environ.get("XDG_SESSION_TYPE", "").lower()
    wayland = "wayland" in session or "WAYLAND_DISPLAY" in os.environ

    if wayland:
        if shutil.which("wl-copy"):
            proc = subprocess.run(
                ["wl-copy", "--type", "image/png"],
                input=png_data, capture_output=True,
            )
            if proc.returncode == 0:
                return
            raise OSError(f"wl-copy failed: {proc.stderr.decode().strip()}")
        raise OSError("wl-copy not found. Install it with: sudo dnf install wl-clipboard")
    else:
        if shutil.which("xclip"):
            proc = subprocess.run(
                ["xclip", "-selection", "clipboard", "-t", "image/png"],
                input=png_data, capture_output=True,
            )
            if proc.returncode == 0:
                return
            raise OSError(f"xclip failed: {proc.stderr.decode().strip()}")
        raise OSError(
            "No clipboard tool found.\\n"
            "  sudo dnf install xclip        # X11\\n"
            "  sudo dnf install wl-clipboard  # Wayland"
        )'''
    br = br.replace(old, new)
    print("  ✓ background_remover.py: clipboard Linux aplicado")

# iconbitmap → iconphoto
if 'self.iconbitmap' in br:
    br = re.sub(
        r"icon_path = .*?resource\(\"icon\.ico\"\).*?pass",
        'icon_path = _resource("icon.png")\n        if not icon_path.exists():\n            icon_path = _resource("icon.ico")\n        if icon_path.exists():\n            try:\n                _ico = tk.PhotoImage(file=str(icon_path))\n                self.iconphoto(True, _ico)\n                self._icon_ref = _ico\n            except Exception:\n                pass',
        br, flags=re.DOTALL
    )
    print("  ✓ background_remover.py: iconphoto aplicado")

# i18n strings
for old, new in [
    ('"Startup error: please open the app using start.bat."',
     '"Startup error: please open the app using start.sh or: python src/main.py"'),
    ('"Drag and drop is unavailable. Install dependencies with start.bat."',
     '"Drag and drop is unavailable. Install with start.sh or: pip install tkinterdnd2"'),
    ('"Erro de inicialização: abra o app usando start.bat."',
     '"Erro de inicialização: abra o app com start.sh ou: python src/main.py"'),
    ('"Arrastar e largar indisponível. Instale as dependências com o start.bat."',
     '"Arrastar e largar indisponível. Instale com start.sh ou: pip install tkinterdnd2"'),
]:
    if old in br:
        br = br.replace(old, new)

BR.write_text(br)
print("  ✓ background_remover.py: salvo")

# ── setup_assistant.py ────────────────────────────────────────────────────
sa = SA.read_text()
changed_sa = False

if 'iconbitmap' in sa:
    sa = sa.replace(
        'ICON_FILE = APP_DIR / "icon.ico"',
        'ICON_FILE = APP_DIR / "icon.png"\nICON_ICO  = APP_DIR / "icon.ico"'
    )
    sa = sa.replace(
        'self.iconbitmap(str(ICON_FILE))',
        '_ico = tk.PhotoImage(file=str(ICON_FILE))\n                self.iconphoto(True, _ico)\n                self._icon_ref = _ico'
    )
    sa = re.sub(r'dialog\.iconbitmap\(str\(ICON_FILE\)\)',
        '_ico = tk.PhotoImage(file=str(ICON_FILE))\n                dialog.iconphoto(True, _ico)\n                dialog._icon_ref = _ico',
        sa)
    changed_sa = True
    print("  ✓ setup_assistant.py: iconphoto aplicado")

if 'pythonw.exe' in sa or 'python.exe' in sa:
    sa = re.sub(
        r'def python_cli_executable.*?return str\(current\)\n\n\ndef python_gui_executable.*?return str\(current\)',
        'def python_cli_executable() -> str:\n    return str(sys.executable)\n\n\ndef python_gui_executable() -> str:\n    return str(sys.executable)',
        sa, flags=re.DOTALL
    )
    changed_sa = True
    print("  ✓ setup_assistant.py: python executável Linux aplicado")

if 'CREATE_NO_WINDOW' in sa:
    sa = sa.replace(
        'return getattr(subprocess, "CREATE_NO_WINDOW", 0)',
        'return 0  # no-op on Linux'
    )
    changed_sa = True

if 'powershell' in sa or '_create_root_shortcut' in sa:
    sa = re.sub(
        r'self\.after\(600, self\._create_root_shortcut\)',
        'self.after(600, self._create_desktop_entry)',
        sa
    )
    changed_sa = True
    print("  ✓ setup_assistant.py: desktop entry aplicado")

if changed_sa:
    SA.write_text(sa)
    print("  ✓ setup_assistant.py: salvo")

# ── updater.py ────────────────────────────────────────────────────────────
upd = UPD.read_text()
if '"sabnck/background-remover-studio"' in upd:
    upd = upd.replace(
        'REPO   = "sabnck/background-remover-studio"',
        'REPO   = "ro2342/background-remover-studio"'
    )
    if '"src/setup_assistant.pyw"' in upd:
        upd = upd.replace(
            '"src/setup_assistant.pyw"',
            '"src/setup_assistant.py"   # Linux: .py instead of .pyw'
        )
    UPD.write_text(upd)
    print("  ✓ updater.py: REPO e tracked files atualizados")

print("\n✓ Todos os patches aplicados com sucesso.")
PYEOF

echo ""
echo "📦  Commitando..."
git add -A
git diff --cached --quiet || git commit -m "chore: sync upstream + reapply Linux patches"

echo ""
echo "🚀  Fazendo push..."
git push origin main

echo ""
echo "✓ Fork sincronizado e atualizado com sucesso!"
