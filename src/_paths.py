"""Resource path helper — works in dev, PyInstaller onedir bundles, and Linux packages.

Usage:
    from _paths import resource, app_root

    icon_path = resource("icon.png")
    web_dir   = resource("webui")
"""

from __future__ import annotations

import sys
from pathlib import Path


def app_root() -> Path:
    """Return the application root directory.

    - PyInstaller onedir bundle: directory containing the binary
    - Development / Linux: src/ directory (parent of this file)
    """
    if getattr(sys, "frozen", False):
        return Path(sys.executable).parent
    return Path(__file__).parent


def resource(relative: str) -> Path:
    """Return an absolute path to a bundled resource file or folder.

    On Linux, prefers .png over .ico for icon files (better TK support).
    """
    path = app_root() / relative
    # Transparent fallback: icon.ico → icon.png on Linux
    if not path.exists() and relative.endswith(".ico"):
        png = app_root() / relative[:-4] + ".png"  # type: ignore[operator]
        png_path = app_root() / (relative[:-4] + ".png")
        if png_path.exists():
            return png_path
    return path
