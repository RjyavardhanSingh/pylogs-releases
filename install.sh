#!/bin/bash
set -e

REPO="RjyavardhanSingh/pylogs-releases"
VERSION="${PYLOGS_VERSION:-latest}"
INSTALL_DIR="${HOME}/.local/bin"
LIB_DIR="${HOME}/.local/lib/pylogs"

echo ""
echo "██████  ██    ██ ██       ██████   ██████   ██████ "
echo "██   ██  ██  ██  ██      ██    ██ ██       ██ ██   "
echo "██████    ████   ██      ██    ██ ██   ███  ██████ "
echo "██         ██    ██      ██    ██ ██    ██    ██ ██"
echo "██         ██    ███████  ██████   ██████   ██████ "
echo "               System Logging, Reimagined."
echo ""

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
    linux)  PLATFORM="linux" ;;
    darwin) PLATFORM="macos" ;;
    msys*|mingw*|cygwin*) PLATFORM="windows" ;;
    *) echo "Error: Unsupported OS: $OS"; exit 1 ;;
esac

# Detect Arch
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)  ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "Error: Unsupported arch: $ARCH"; exit 1 ;;
esac

# Resolve version
if [ "$VERSION" = "latest" ]; then
    echo "Resolving latest version..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    if [ -z "$VERSION" ]; then
        echo "Error: Could not resolve latest version. Check https://github.com/$REPO/releases"
        exit 1
    fi
fi

echo "Platform:  $PLATFORM-$ARCH"
echo "Version:   v$VERSION"
echo ""

# Download binary
BINARY_URL="https://github.com/$REPO/releases/download/v${VERSION}/pylogs-${PLATFORM}-${ARCH}"
echo "Downloading binary from:"
echo "  $BINARY_URL"

mkdir -p "$INSTALL_DIR"
if ! curl -fsSL "$BINARY_URL" -o "$INSTALL_DIR/pylogs"; then
    echo ""
    echo "Error: Download failed. Check if v$VERSION exists for $PLATFORM-$ARCH"
    echo "  https://github.com/$REPO/releases"
    exit 1
fi
chmod +x "$INSTALL_DIR/pylogs"

# Install hook module
mkdir -p "$LIB_DIR"
HOOK_URL="https://github.com/$REPO/releases/download/v${VERSION}/pylogs_hook.py"
echo "Downloading hook module from:"
echo "  $HOOK_URL"

if ! curl -fsSL "$HOOK_URL" -o "$LIB_DIR/pylogs_hook.py"; then
    echo ""
    echo "Warning: Could not download hook module. You can copy pylogs_hook.py manually."
fi

echo ""
echo "============================================"
echo "  Installation complete!"
echo "============================================"
echo ""
echo "  Binary:  $INSTALL_DIR/pylogs"
echo "  Hook:    $LIB_DIR/pylogs_hook.py"
echo ""

# Check PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "  Add to your shell profile (~/.bashrc, ~/.zshrc):"
    echo ""
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi

# Check PYTHONPATH
if [[ ":$PYTHONPATH:" != *":$LIB_DIR:"* ]]; then
    echo "  Add to your shell profile (~/.bashrc, ~/.zshrc):"
    echo ""
    echo "    export PYTHONPATH=\"\$HOME/.local/lib/pylogs:\$PYTHONPATH\""
    echo ""
fi

cat << 'SETUP'
============================================
  Quick Start
============================================

  Step 1: Set environment (one-time)
  ----------------------------------------
    Add to ~/.bashrc or ~/.zshrc:

      export PATH="$HOME/.local/bin:$PATH"
      export PYTHONPATH="$HOME/.local/lib/pylogs:$PYTHONPATH"

    Then: source ~/.bashrc

  Step 2: Initialize pylogs in your project
  ----------------------------------------
    cd your_project
    pylogs init

    This creates .pylogs/config.json in your project.

  Step 3: Add ONE line to your launcher script
  ----------------------------------------
    In your main.py, app.py, or any entry point, add at the very top:

    from pylogs_hook import patch; patch()

    Example:
    ------------------------------------
    from pylogs_hook import patch; patch()   # <-- Add this line

    import logging
    logger = logging.getLogger(__name__)

    def main():
        logger.info("App started")
        # ... your app code ...

    if __name__ == "__main__":
        main()
    ------------------------------------

    That's it! All logs from any logger in your project will be
    captured to SQLite automatically.

  Step 4: Run your app normally
  ----------------------------------------
    python main.py

    Logs are captured in real-time to pylogs.db in your project directory.

  Step 5: View logs in the TUI
  ----------------------------------------
    pylogs

    Keybindings:
    - Up/Down: Navigate logs
    - Enter:   View log details
    - A:       Ask AI to analyze selected log
    - P:       Switch AI provider
    - F:       Filter logs (case-insensitive: warning, WARNING, warn)
    - R:       Reset filters
    - C:       Clear database
    - Q:       Quit

SETUP
