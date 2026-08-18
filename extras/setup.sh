#!/usr/bin/env bash
# setup.sh — One-command setup for Token Usage Monitor widget
# Installs: ccusage, wrapper script, systemd timer, QML XHR permission
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
err()  { echo -e "${RED}✗${NC} $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WRAPPER_SRC="$SCRIPT_DIR/ccusage-wrapper"
SERVICE_SRC="$SCRIPT_DIR/ccusage-data.service"
TIMER_SRC="$SCRIPT_DIR/ccusage-data.timer"

echo "=== Token Usage Monitor — Setup ==="
echo ""

# 1. Check/install ccusage
if command -v ccusage &>/dev/null; then
    ok "ccusage already installed ($(ccusage --version 2>/dev/null || echo 'unknown version'))"
elif command -v bun &>/dev/null; then
    echo "Installing ccusage via bun..."
    bun add -g ccusage && ok "ccusage installed via bun" || err "Failed to install ccusage via bun"
elif command -v npm &>/dev/null; then
    echo "Installing ccusage via npm..."
    npm install -g ccusage && ok "ccusage installed via npm" || err "Failed to install ccusage via npm"
elif command -v npx &>/dev/null; then
    warn "ccusage not installed. You can run it via: npx ccusage daily"
    warn "For the timer to work, install it first: npm install -g ccusage"
else
    err "No Node.js package manager found. Install Node.js first:"
    err "  https://nodejs.org/"
    exit 1
fi

# 2. Install ccusage wrapper script
mkdir -p "$HOME/.local/bin"
if [ -f "$WRAPPER_SRC" ]; then
    cp "$WRAPPER_SRC" "$HOME/.local/bin/ccusage-wrapper"
    chmod +x "$HOME/.local/bin/ccusage-wrapper"
    ok "Wrapper script installed to ~/.local/bin/ccusage-wrapper"
else
    err "ccusage-wrapper not found at $WRAPPER_SRC"
fi

# 3. Install systemd timer
mkdir -p "$HOME/.config/systemd/user"

# Fix hardcoded path in service file — use $HOME dynamically
TEMP_SERVICE=$(mktemp)
sed "s|ExecStart=.*|ExecStart=$HOME/.local/bin/ccusage-wrapper|" "$SERVICE_SRC" > "$TEMP_SERVICE"

cp "$TEMP_SERVICE" "$HOME/.config/systemd/user/ccusage-data.service"
rm -f "$TEMP_SERVICE"
cp "$TIMER_SRC" "$HOME/.config/systemd/user/ccusage-data.timer"
ok "Systemd timer installed to ~/.config/systemd/user/"

systemctl --user daemon-reload
systemctl --user enable --now ccusage-data.timer 2>/dev/null && ok "Timer enabled (runs every 5 min)" || warn "Timer enable failed — check manually"

# 4. QML XHR file read permission
XHR_DIR="$HOME/.config/systemd/user/plasma-plasmashell.service.d"
XHR_CONF="$XHR_DIR/xhr.conf"

if [ -f "$XHR_CONF" ] && grep -q "QML_XHR_ALLOW_FILE_READ" "$XHR_CONF" 2>/dev/null; then
    ok "QML XHR file read already configured"
else
    mkdir -p "$XHR_DIR"
    cat > "$XHR_CONF" << 'XHREOF'
[Service]
Environment="QML_XHR_ALLOW_FILE_READ=1"
XHREOF
    systemctl --user daemon-reload 2>/dev/null
    ok "QML XHR file read configured"
    warn "Restart plasmashell to apply: systemctl --user restart plasma-plasmashell"
fi

# 5. Generate initial data
if command -v ccusage &>/dev/null; then
    echo ""
    echo "Generating initial data..."
    bash "$HOME/.local/bin/ccusage-wrapper" && ok "Data file created" || warn "ccusage run failed — will retry in 5 min"
fi

echo ""
echo "=== Setup complete! ==="
echo "Add the widget: right-click panel → Add Widgets → 'Token Usage Monitor'"
