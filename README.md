# Token Usage Monitor

KDE Plasma 6 system tray widget that displays AI coding agent token usage, powered by [ccusage](https://github.com/ccusage/ccusage).

## Features

- System tray icon with token count tooltip
- Popup with today's token usage, model breakdown, and 7-day history
- Configurable refresh interval and data file path
- Supports Claude Code, OpenCode, Codex, and 16+ AI agents via ccusage

## Requirements

- KDE Plasma 6
- [ccusage](https://github.com/ccusage/ccusage) installed (`bun add -g ccusage`)
- ccusage data timer running (see below)

## Install

### Manual

```bash
# Clone the repo
git clone https://github.com/abuamar142/plasma-tokenusage.git
cd plasma-tokenusage

# Install widget
plasma-plasmoidinstall package/

# Or symlink (for development)
ln -sf "$(pwd)" ~/.local/share/plasma/plasmoids/com.github.abuamar.tokenusage
```

### Data Timer Setup

The widget reads from `~/.cache/ccusage/tokenusage.json`. Set up automatic data collection:

```bash
# Install ccusage wrapper
cp extras/ccusage-wrapper ~/.local/bin/ccusage-wrapper
chmod +x ~/.local/bin/ccusage-wrapper

# Install systemd timer
cp extras/ccusage-data.service ~/.config/systemd/user/
cp extras/ccusage-data.timer ~/.config/systemd/user/

systemctl --user enable --now ccusage-data.timer
```

### QML XHR File Access

Plasma widgets need permission to read local files via XHR:

```bash
mkdir -p ~/.config/systemd/user/plasma-plasmashell.service.d/
cat > ~/.config/systemd/user/plasma-plasmashell.service.d/xhr.conf << 'EOF'
[Service]
Environment="QML_XHR_ALLOW_FILE_READ=1"
EOF

systemctl --user daemon-reload
```

## Configuration

Right-click the tray icon → Configure. Options:

- **Refresh interval**: 10-300 seconds (default: 30)
- **Data file path**: Path to ccusage JSON output (default: `~/.cache/ccusage/tokenusage.json`)
- **Show cost**: Display cost in tooltip
- **Show breakdown**: Show model breakdown in popup

## License

GPL-2.0+
