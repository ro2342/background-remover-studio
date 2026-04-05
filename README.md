# Background Remover Studio — Linux Fork

> **[English](#english) | [Português BR](#português-br)**

> **Linux fork** of [sabnck/background-remover-studio](https://github.com/sabnck/background-remover-studio).  
> All credit for the original app goes to **Henrique Fernandes** ([@oportunipt](https://instagram.com/oportunipt)).  
> This fork ports the app to **Fedora, Ubuntu, Debian, Arch** and other Linux distributions.

---

## English

A free, local, and privacy-first background remover. Everything runs on your machine — no internet required after the first model download, no account, no upload limits.

### What changed in this fork

| Area | Original (Windows) | This fork (Linux) |
|---|---|---|
| Launcher | `start.bat` | `start.sh` |
| Uninstall | `src/uninstall.bat` | `src/uninstall.sh` |
| Setup assistant | `setup_assistant.pyw` | `setup_assistant.py` |
| App icon | `iconbitmap()` (.ico only) | `iconphoto()` (.png, works on all TK platforms) |
| Clipboard | `ctypes.windll` (Win32 API) | `wl-copy` (Wayland) / `xclip` (X11) |
| Desktop shortcut | `.lnk` via PowerShell | `.desktop` entry via `install-desktop-entry.sh` |
| App menu | — | GNOME/KDE/XFCE menu entry auto-created on first run |

### Features

- Modern dark desktop UI with English / Portuguese toggle
- Batch background removal (process multiple images at once)
- Drag and drop image import
- Adaptive processing — different logic for photos vs. artwork/logos
- Edge refinement tools (smoothing, erosion, hair protection)
- Export to PNG, WebP, TIFF, JPG, and BMP
- Copy processed output directly to the clipboard (Wayland + X11)
- Guided setup assistant (install, repair, and cleanup — all in a GUI)
- Web UI coming soon

### System Requirements

- **Fedora 38+** / Ubuntu 22.04+ / Debian 12+ / Arch Linux (or any modern distro)
- **Python 3.10+** with tkinter

Install system dependencies first:

```bash
# Fedora / RHEL / CentOS Stream
sudo dnf install python3 python3-pip python3-tkinter

# Ubuntu / Debian
sudo apt install python3 python3-pip python3-tk

# Arch Linux
sudo pacman -S python python-pip tk
```

For clipboard support (copy image to clipboard):

```bash
# Wayland (default on Fedora 40+ with GNOME)
sudo dnf install wl-clipboard        # Fedora
sudo apt install wl-clipboard        # Ubuntu/Debian

# X11
sudo dnf install xclip               # Fedora
sudo apt install xclip               # Ubuntu/Debian
```

### Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/background-remover-studio.git
cd background-remover-studio
chmod +x start.sh
./start.sh
```

`start.sh` will:
1. Check for Python 3.10+ (and try to install it via `dnf`/`apt` if missing)
2. Create a `.venv` virtual environment automatically
3. Open the setup assistant GUI
4. On first run: click **"Install / Repair Dependencies"**, then **"Open App → Desktop App"**

### GNOME / KDE App Menu

After the first run the app automatically creates an entry in `~/.local/share/applications/`.  
You can also install it manually:

```bash
chmod +x install-desktop-entry.sh
./install-desktop-entry.sh
```

### Manual Start (advanced)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python src/main.py
```

### What Gets Installed

| Package | Version | Purpose |
|---|---|---|
| `rembg[cpu]` | latest | AI background removal engine |
| `pillow` | latest | Image processing |
| `numpy` | latest | Numerical computing |
| `tkinterdnd2` | latest | Drag and drop support |

> **First run note:** On the first background removal, `rembg` downloads the **u2net AI model (~170 MB)** and saves it to `~/.u2net/`. This only happens once — after that the app works fully offline.

### Uninstall / Cleanup

```bash
./src/uninstall.sh
```

Or use the **"Uninstall / Cleanup"** button inside the setup assistant.  
For a full removal, delete the project folder and `.venv` after cleanup.

### Project Structure

```
background-remover-studio/
├── start.sh                           # Linux launcher — replaces start.bat
├── install-desktop-entry.sh           # Installs GNOME/KDE app menu entry
├── background-remover-studio.desktop  # .desktop template
├── requirements.txt
├── LICENSE
├── README.md
└── src/
    ├── main.py                 # Desktop app entry point
    ├── background_remover.py   # Desktop UI + AI pipeline (Linux clipboard)
    ├── setup_assistant.py      # Setup / repair / cleanup GUI (Linux port)
    ├── api_server.py           # Local FastAPI server (Web UI — coming soon)
    ├── uninstall.sh            # Uninstall entry point — replaces uninstall.bat
    ├── icon.png                # App icon (PNG, works on all TK platforms)
    ├── icon.ico                # Original icon (kept for reference)
    └── webui/
        ├── index.html
        ├── app.js
        └── styles.css
```

### Export Formats

| Format | Transparency | Notes |
|---|---|---|
| PNG | ✅ | Lossless, recommended |
| WebP | ✅ | Smaller file size |
| TIFF | ✅ | Lossless, for print workflows |
| JPG | ❌ | White background fill |
| BMP | ❌ | White background fill |

### License

MIT — see [LICENSE](LICENSE)

### Credits

Original app by **Henrique Fernandes**  
LinkedIn: [linkedin.com/in/henriquehsf](https://pt.linkedin.com/in/henriquehsf)  
Instagram / Company: [@oportunipt](https://instagram.com/oportunipt)

Linux port maintained in this fork.

---

## Português BR

Fork Linux do [sabnck/background-remover-studio](https://github.com/sabnck/background-remover-studio).  
Todo o crédito pelo app original é do **Henrique Fernandes** ([@oportunipt](https://instagram.com/oportunipt)).  
Este fork porta o app para **Fedora, Ubuntu, Debian, Arch** e outras distribuições Linux.

---

Removedor de fundo gratuito, local e com privacidade total. Tudo roda na sua máquina — sem internet depois do primeiro download do modelo, sem conta, sem limite de uploads.

### O que mudou neste fork

| Área | Original (Windows) | Este fork (Linux) |
|---|---|---|
| Launcher | `start.bat` | `start.sh` |
| Desinstalar | `src/uninstall.bat` | `src/uninstall.sh` |
| Assistente de setup | `setup_assistant.pyw` | `setup_assistant.py` |
| Ícone do app | `iconbitmap()` (só .ico) | `iconphoto()` (.png, funciona em todo TK) |
| Área de transferência | `ctypes.windll` (Win32 API) | `wl-copy` (Wayland) / `xclip` (X11) |
| Atalho no desktop | `.lnk` via PowerShell | entrada `.desktop` via `install-desktop-entry.sh` |
| Menu do sistema | — | GNOME/KDE/XFCE — criado automaticamente no 1º uso |

### Funcionalidades

- Interface desktop dark moderna com botão English / Português
- Remoção em lote (processa várias imagens de uma vez)
- Importação por arrasto (drag and drop)
- Processamento adaptativo — lógica diferente para fotos vs. arte/logos
- Ferramentas de refinamento de borda (suavização, erosão, proteção de cabelo)
- Exportação em PNG, WebP, TIFF, JPG e BMP
- Copiar resultado para a área de transferência (Wayland + X11)
- Assistente de setup guiado (instalar, reparar e limpar — tudo em GUI)
- Interface Web em breve

### Requisitos do sistema

- **Fedora 38+** / Ubuntu 22.04+ / Debian 12+ / Arch Linux
- **Python 3.10+** com tkinter

Instale as dependências do sistema primeiro:

```bash
# Fedora / RHEL / CentOS Stream
sudo dnf install python3 python3-pip python3-tkinter

# Ubuntu / Debian
sudo apt install python3 python3-pip python3-tk

# Arch Linux
sudo pacman -S python python-pip tk
```

Para suporte à área de transferência:

```bash
# Wayland (padrão no Fedora 40+ com GNOME)
sudo dnf install wl-clipboard

# X11
sudo dnf install xclip
```

### Início Rápido

```bash
git clone https://github.com/SEU_USUARIO/background-remover-studio.git
cd background-remover-studio
chmod +x start.sh
./start.sh
```

O `start.sh` vai:
1. Verificar Python 3.10+ (e tentar instalar via `dnf`/`apt` se necessário)
2. Criar um ambiente virtual `.venv` automaticamente
3. Abrir o assistente de setup em GUI
4. Na primeira vez: clique em **"Instalar / Reparar Dependências"**, depois **"Abrir App → App Desktop"**

### Menu do GNOME / KDE

Após o primeiro uso o app cria automaticamente uma entrada em `~/.local/share/applications/`.  
Também é possível instalar manualmente:

```bash
chmod +x install-desktop-entry.sh
./install-desktop-entry.sh
```

### Início Manual (avançado)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python src/main.py
```

### O que é instalado

| Pacote | Versão | Função |
|---|---|---|
| `rembg[cpu]` | mais recente | Motor de IA para remoção de fundo |
| `pillow` | mais recente | Processamento de imagens |
| `numpy` | mais recente | Computação numérica |
| `tkinterdnd2` | mais recente | Suporte a arrastar e soltar |

> **Nota sobre o primeiro uso:** Na primeira remoção de fundo, o `rembg` baixa o **modelo u2net (~170 MB)** e salva em `~/.u2net/`. Isso acontece uma única vez — depois o app funciona completamente offline.

### Desinstalar / Limpar

```bash
./src/uninstall.sh
```

Ou use o botão **"Desinstalar / Limpar"** dentro do assistente.  
Para remover completamente, apague a pasta do projeto e o `.venv` após a limpeza.

### Estrutura do Projeto

```
background-remover-studio/
├── start.sh                           # Launcher Linux — substitui o start.bat
├── install-desktop-entry.sh           # Instala entrada no menu do GNOME/KDE
├── background-remover-studio.desktop  # Template .desktop
├── requirements.txt
├── LICENSE
├── README.md
└── src/
    ├── main.py                 # Ponto de entrada do app desktop
    ├── background_remover.py   # Interface + pipeline de IA (clipboard Linux)
    ├── setup_assistant.py      # GUI de setup / reparo / limpeza (port Linux)
    ├── api_server.py           # Servidor FastAPI local (Interface Web — em breve)
    ├── uninstall.sh            # Desinstalação — substitui o uninstall.bat
    ├── icon.png                # Ícone PNG (funciona em todo TK)
    ├── icon.ico                # Ícone original (mantido para referência)
    └── webui/
        ├── index.html
        ├── app.js
        └── styles.css
```

### Formatos de Exportação

| Formato | Transparência | Notas |
|---|---|---|
| PNG | ✅ | Sem perda de qualidade, recomendado |
| WebP | ✅ | Arquivo menor |
| TIFF | ✅ | Sem perda, para impressão |
| JPG | ❌ | Fundo branco |
| BMP | ❌ | Fundo branco |

### Licença

MIT — veja [LICENSE](LICENSE)

### Créditos

App original por **Henrique Fernandes**  
LinkedIn: [linkedin.com/in/henriquehsf](https://pt.linkedin.com/in/henriquehsf)  
Instagram / Empresa: [@oportunipt](https://instagram.com/oportunipt)

Port Linux mantido neste fork.
