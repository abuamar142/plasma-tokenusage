# Token Usage Monitor

KDE Plasma 6 system tray widget that displays AI coding agent token usage, powered by [ccusage](https://github.com/ccusage/ccusage).

![Plasma 6](https://img.shields.io/badge/Plasma-6-blue)
![License](https://img.shields.io/badge/License-GPL--2.0%2B-green)

## Features

- System tray icon with token count tooltip
- Popup with today's token usage, model breakdown, and 7-day history
- Configurable refresh interval and data file path
- Supports Claude Code, OpenCode, Codex, and 16+ AI agents via ccusage
- Auto-refresh every 5 minutes via systemd timer

## Screenshots

| Tray Icon | Popup Detail |
|-----------|-------------|
| ![Hover](screenshots/hover.png) | ![Detail](screenshots/detail.png) |

| Desktop |
|---------|
| ![Desktop](screenshots/desktop.png) |

## Requirements

- KDE Plasma 6
- Node.js runtime (for ccusage — [install guide](https://nodejs.org/))
- One of: `bun`, `npm`, or `npx`

## Install

### Option 1 — One-Line Setup (Recommended)

```bash
git clone https://github.com/abuamar142/plasma-tokenusage.git && cd plasma-tokenusage && bash extras/setup.sh
```

This installs everything automatically:
1. Installs [ccusage](https://github.com/ccusage/ccusage) via bun or npm
2. Copies the data wrapper to `~/.local/bin/ccusage-wrapper`
3. Enables a systemd timer (every 5 min) to generate usage JSON
4. Configures QML file read permission for Plasma
5. Generates the initial data file

After setup, add the widget: **right-click panel → Add Widgets → search "Token Usage Monitor"**.

### Option 2 — Manual Install

**Step 1: Install the widget**

```bash
git clone https://github.com/abuamar142/plasma-tokenusage.git
cd plasma-tokenusage

# Option A: Symlink (easier for updates)
mkdir -p ~/.local/share/plasma/plasmoids
ln -sf "$(pwd)" ~/.local/share/plasma/plasmoids/com.github.abuamar.tokenusage

# Option B: System-wide install
plasma-plasmoidinstall ./
```

**Step 2: Install ccusage**

```bash
# Pick your package manager
bun add -g ccusage      # or
npm install -g ccusage   # or
pnpm add -g ccusage
```

**Step 3: Set up the data pipeline**

```bash
# Install wrapper script
mkdir -p ~/.local/bin
cp extras/ccusage-wrapper ~/.local/bin/ccusage-wrapper
chmod +x ~/.local/bin/ccusage-wrapper

# Install systemd timer
cp extras/ccusage-data.service ~/.config/systemd/user/
cp extras/ccusage-data.timer ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now ccusage-data.timer
```

**Step 4: Configure Plasma XHR permission**

The widget reads a local JSON file via QML `XMLHttpRequest`. Plasma sandbox blocks this by default. Create a systemd drop-in:

```bash
mkdir -p ~/.config/systemd/user/plasma-plasmashell.service.d
cat > ~/.config/systemd/user/plasma-plasmashell.service.d/xhr.conf << 'EOF'
[Service]
Environment="QML_XHR_ALLOW_FILE_READ=1"
EOF
systemctl --user daemon-reload
```

**Step 5: Restart Plasma and add widget**

```bash
systemctl --user restart plasma-plasmashell
```

Then: **right-click panel → Add Widgets → search "Token Usage Monitor"**.

### Option 3 — .plasmoid File

If you have the `.plasmoid` file (from a release or download):

```bash
# Using the KDE CLI tool
plasma-plasmoidinstall com.github.abuamar.tokenusage.plasmoid

# Or manually extract
mkdir -p ~/.local/share/plasma/plasmoids/com.github.abuamar.tokenusage
cd ~/.local/share/plasma/plasmoids/com.github.abuamar.tokenusage
unzip /path/to/com.github.abuamar.tokenusage.plasmoid
```

Then run the setup script for ccusage + timer:

```bash
git clone https://github.com/abuamar142/plasma-tokenusage.git
bash plasma-tokenusage/extras/setup.sh
```

## Configuration

Right-click the tray icon → **Configure**. Options:

| Setting | Default | Description |
|---------|---------|-------------|
| Refresh interval | 30s | How often widget polls for new data (10–300s) |
| Data file path | `~/.cache/ccusage/tokenusage.json` | Path to ccusage JSON output |
| Show cost | on | Display cost in tooltip |
| Show breakdown | on | Show model breakdown in popup |

## How It Works

```
AI coding agents → ~/.local/share/ccusage/*.jsonl (raw agent data)
                        ↓
              ccusage CLI (every 5 min via systemd timer)
                        ↓
              ~/.cache/ccusage/tokenusage.json (aggregated JSON)
                        ↓
              Plasma widget reads via XMLHttpRequest + QML Timer
                        ↓
              Tray icon tooltip + popup display
```

## Supported AI Agents

Via ccusage, this widget tracks tokens from:

- Claude Code, Codex, OpenCode, Pi, Hermes Agent
- Droid, Codebuff, Goose, Kilo, Kimi, Qwen
- GitHub Copilot CLI, Gemini CLI, Grok Build
- And more... ([full list](https://github.com/ccusage/ccusage))

## Troubleshooting

### Widget shows "Unable to load data"

1. **Check ccusage is installed:** `which ccusage`
2. **Check timer is running:** `systemctl --user status ccusage-data.timer`
3. **Check data file exists:** `ls -la ~/.cache/ccusage/tokenusage.json`
4. **Generate manually:** `ccusage-wrapper`
5. **Check XHR permission:** `systemctl --user status plasma-plasmashell` — the process should have `QML_XHR_ALLOW_FILE_READ=1` in its environment

### Widget icon not appearing in panel

Restart Plasma after install:

```bash
systemctl --user restart plasma-plasmashell
```

### Timer not running

```bash
systemctl --user status ccusage-data.timer
# If inactive:
systemctl --user enable --now ccusage-data.timer
```

### Data is stale / not updating

Check the timer last ran:

```bash
systemctl --user list-timers ccusage-data.timer
```

Manually trigger a data refresh:

```bash
ccusage-wrapper
```

## License

GPL-2.0+ — see [LICENSE](LICENSE)
