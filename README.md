# Windows-to-macOS Migration Toolkit

Automated migration of your development environment from Windows to macOS.
Export your installed apps, VS Code extensions, and config from Windows, then
run a single script on your Mac to install everything.

## What's Inside

```
mac-migration/
├── scripts/
│   ├── scan_windows.ps1      # Run on Windows — exports apps, extensions, config
│   ├── scan_claude.ps1       # Run on Windows — exports Claude Code & Desktop config
│   ├── full_setup.sh         # Run on macOS  — installs everything (10 stages)
│   └── migrate_claude.sh     # Run on macOS  — deploys Claude config with path surgery
├── apps/
│   ├── brew_apps.txt         # Curated Homebrew install commands
│   ├── windows_apps_raw.txt  # (generated) Raw Windows app inventory
│   ├── npm_globals.txt       # (generated) Global npm packages
│   └── git_config.txt        # (generated) Git global config
├── claude/                   # (generated) Claude Code & Desktop config export
│   ├── settings.json         # Permissions, hooks, plugins
│   ├── CLAUDE.md             # Global system instructions
│   ├── SKILLS.md             # Curated skills index
│   ├── .claudeignore         # File ignore patterns
│   ├── claude_desktop_config.json  # Desktop app preferences
│   ├── agents/               # Custom agent definitions (~40 files)
│   ├── reference/            # Reference docs (tech stack, anti-patterns, etc.)
│   └── projects/             # Per-project memories
└── vscode/
    ├── vscode_extensions.txt # VS Code extension IDs
    └── install_extensions.sh # Extension installer script
```

---

## Pre-requisites

Before running the setup on your Mac, ensure you have:

1. **Admin access** on the Mac (you'll be prompted for your password during installs)
2. **Internet connection** (Homebrew and casks download from the internet)
3. **Xcode Command Line Tools** — the setup script installs these automatically,
   but you can install them manually first: `xcode-select --install`
4. **Rosetta 2** (Apple Silicon only) — also installed automatically by the setup
   script. Some Intel-only apps require it.

---

## Step 1: Export from Windows

On your **Windows** machine, open PowerShell and run:

```powershell
# Navigate to the repo
cd path\to\mac-migration

# Export apps, extensions, and config
powershell -ExecutionPolicy Bypass -File scripts\scan_windows.ps1

# Export Claude Code & Desktop configuration
powershell -ExecutionPolicy Bypass -File scripts\scan_claude.ps1
```

The first script generates four files:

| File | Contents |
|---|---|
| `apps/windows_apps_raw.txt` | Registry + winget app inventory |
| `apps/npm_globals.txt` | Global npm packages |
| `apps/git_config.txt` | Git global config (name, email, aliases) |
| `vscode/vscode_extensions.txt` | All installed VS Code extension IDs |

The second script exports Claude configuration into `claude/`:

| Directory/File | Contents |
|---|---|
| `claude/settings.json` | Permissions, hooks, enabled plugins |
| `claude/CLAUDE.md` | Global system instructions |
| `claude/SKILLS.md` | Curated skills index |
| `claude/.claudeignore` | File ignore patterns |
| `claude/claude_desktop_config.json` | Desktop app preferences |
| `claude/agents/` | Custom agent definitions |
| `claude/reference/` | Reference docs (tech stack, anti-patterns) |
| `claude/projects/` | Per-project memories |

> **Note:** The repo ships with a pre-populated `vscode_extensions.txt` and
> `brew_apps.txt`. Re-running the scan updates the extensions list but you'll
> need to manually update `brew_apps.txt` if you've installed new apps since
> the initial mapping.

### Transferring to your Mac

Pick whichever method is easiest:

- **Git:** Push the repo to GitHub/GitLab, then `git clone` on your Mac
- **AirDrop:** Right-click the folder -> Share -> AirDrop
- **USB drive:** Copy the folder to a USB stick
- **iCloud/OneDrive:** Drop it into a synced folder

---

## Step 2: Install Homebrew

The `full_setup.sh` script handles this automatically. If you prefer to install
it manually first:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installation, Homebrew lives at:
- **Apple Silicon (M1/M2/M3/M4):** `/opt/homebrew/bin/brew`
- **Intel Macs:** `/usr/local/bin/brew`

Add it to your shell profile if not already done:

```bash
# Apple Silicon — add to ~/.zshrc
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel — usually automatic, but if needed:
eval "$(/usr/local/bin/brew shellenv)"
```

Verify: `brew --version`

---

## Step 3: Install Applications

### Option A: Automated (recommended)

Run the master setup script — it handles Homebrew, all apps, npm packages, and
VS Code extensions in one shot:

```bash
bash scripts/full_setup.sh
```

### Option B: Manual / selective

Run individual brew commands from `apps/brew_apps.txt`:

```bash
# Install everything in the file
while IFS= read -r line; do
    [[ "$line" =~ ^#|^$ ]] && continue
    eval "$line"
done < apps/brew_apps.txt

# Or cherry-pick specific lines:
brew install git
brew install --cask visual-studio-code
brew install --cask docker
```

> **Tip:** Some casks (like Docker, VS Code) will prompt for your admin password.
> This is normal — macOS requires it for apps installed to `/Applications`.

---

## Step 4: Install VS Code Extensions

If you used `full_setup.sh`, extensions are already installed. Otherwise:

```bash
bash vscode/install_extensions.sh
```

The script:
- Reads each extension ID from `vscode/vscode_extensions.txt`
- Skips Windows-only extensions (e.g., WSL remote)
- Reports a summary of installed/skipped/failed extensions

---

## Step 5: VS Code Settings Sync (Optional)

VS Code has built-in Settings Sync that carries over your settings, keybindings,
snippets, and UI state across machines:

1. Open VS Code on your Mac
2. Press `Cmd+Shift+P` and search for **"Settings Sync: Turn On"**
3. Sign in with your **GitHub** or **Microsoft** account
4. Choose what to sync (Settings, Keybindings, Extensions, UI State, Profiles)
5. VS Code will merge your Windows settings with the Mac installation

> Settings Sync handles extensions too, so you may see duplicates if you already
> ran `install_extensions.sh`. This is harmless — VS Code deduplicates them.

---

## Step 6: Claude Code & Desktop Configuration

`full_setup.sh` Stage 10 handles this automatically. To run standalone:

```bash
bash scripts/migrate_claude.sh
```

### What gets migrated

- **settings.json** — permissions, hooks, enabled plugins (paths auto-transformed)
- **CLAUDE.md** — global system instructions
- **SKILLS.md** — curated skills index
- **.claudeignore** — file ignore patterns
- **~40 custom agents** — all `.agent.md` definitions (archived agents excluded)
- **Reference docs** — tech stack, anti-patterns, agent handoff protocol
- **Project memories** — per-project context and feedback (directory names remapped)
- **Claude Desktop config** — trusted folders, preferences (paths auto-transformed)

### Path transformation

The migration script automatically converts Windows paths to macOS equivalents:

| Windows Format | macOS Result |
|---|---|
| `C:/Users/you/Repo` | `/Users/you/Repo` |
| `C:\\Users\\you\\Repo` | `/Users/you/Repo` |
| `//c/Users/you/Repo` | `/Users/you/Repo` |

### What does NOT migrate

| Item | Why | Action needed |
|---|---|---|
| Plugins & skills | Re-downloaded from marketplace on first use | None |
| OAuth tokens | Platform-specific, can't transfer | Sign in again |
| Sessions & cache | Ephemeral | None |
| Audit log & history | Machine-specific | None |

### Post-deploy

After migration, you must manually:
1. **Authenticate Claude Code** — run `claude` in terminal and sign in
2. **Sign into Claude Desktop** — open the app and log in
3. **Review hooks** — check `~/.claude/settings.json` for any paths that
   reference locations specific to your Windows layout (e.g., homelab-infra)

---

## Troubleshooting

### `brew doctor` — general health check

```bash
brew doctor
```

Fixes most common issues. Run this first if anything seems off.

### Cask quarantine errors

macOS Gatekeeper may block downloaded apps with:
> "App can't be opened because it is from an unidentified developer"

Fix per-app:

```bash
xattr -d com.apple.quarantine /Applications/SomeApp.app
```

Or install without quarantine in the first place:

```bash
brew install --cask --no-quarantine some-app
```

### Keg-only formulas not in PATH

Versioned formulas like `node@22`, `python@3.13`, and `postgresql@17` are
"keg-only" — Homebrew installs them but doesn't symlink them to `/usr/local/bin`.

If `node`, `python3.13`, or `psql` aren't found after install, add to `~/.zshrc`:

```bash
export PATH="$(brew --prefix node@22)/bin:$PATH"
export PATH="$(brew --prefix python@3.13)/bin:$PATH"
export PATH="$(brew --prefix postgresql@17)/bin:$PATH"
```

Then reload: `source ~/.zshrc`

> `full_setup.sh` prints the exact lines you need at the end of its run.

### Rosetta 2 failures on Apple Silicon

If a cask fails with architecture errors:

```bash
# Install Rosetta 2 manually
softwareupdate --install-rosetta --agree-to-license
```

### VS Code extension not found

Some extensions may have been deprecated or renamed since the export. The install
script reports these at the end. Search the
[VS Code Marketplace](https://marketplace.visualstudio.com/) for replacements.

### macOS version requirements

Some casks require a minimum macOS version. If a cask fails, check:

```bash
brew info --cask some-app
```

Look for the `depends_on` section to see version requirements.

### Claude Code hooks not working

If hooks fail after migration, the most likely cause is un-transformed paths.
Check `~/.claude/settings.json` for any remaining Windows paths:

```bash
grep -n 'C:/' ~/.claude/settings.json
grep -n '\\\\' ~/.claude/settings.json
```

Fix any remaining paths manually — the migration script handles the common
patterns but custom paths may slip through.

---

## Notes on Windows-Only Apps

These apps from your Windows machine have no direct macOS version.
Suggested alternatives are listed below.

| Windows App | macOS Alternative |
|---|---|
| Visual Studio Community 2026 | VS Code + C# Dev Kit, or JetBrains Rider |
| Everything (file search) | Spotlight (built-in), Alfred, or Raycast |
| Revo Uninstaller | AppCleaner (free) |
| TeraCopy | Not needed — Finder copy works fine |
| TreeSize Free | GrandPerspective (`brew install --cask grandperspective`) |
| FanControl | Macs Fan Control (`brew install --cask macs-fan-control`) |
| DiskGenius | Disk Utility (built-in) |
| GlassWire | Little Snitch (`brew install --cask little-snitch`) |
| Norton 360 | macOS built-in security (Gatekeeper + XProtect) |
| WinDbg | lldb (built-in with Xcode CLI tools) |
| RivaTuner Statistics Server | iStat Menus (`brew install --cask istat-menus`) |
| NVIDIA / AMD drivers | Not applicable — Apple Silicon has a unified GPU |
| MSI Center | Not applicable — PC motherboard utility |
| WSL | Not needed — macOS is native Unix |
| EA Sports FC 24 | Not available on macOS |
| Forza Horizon 5 | Not available on macOS |
| MetaTrader 5 | Web version or Wine |
| uTorrent | Transmission (`brew install --cask transmission`) |
| Plus500 | Web version |
| CPU-Z | Activity Monitor (built-in) or iStat Menus |
| Autoruns (Sysinternals) | Not needed on macOS |
| Notepad++ | VS Code, Sublime Text, or BBEdit |

---

## Post-Migration Checklist

After running the setup, complete these manual steps:

- [ ] **Configure Git identity** (reference `apps/git_config.txt` from your export):
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "you@example.com"
  ```

- [ ] **Generate SSH keys** for GitHub:
  ```bash
  ssh-keygen -t ed25519 -C "you@example.com"
  # Add the public key to https://github.com/settings/keys
  cat ~/.ssh/id_ed25519.pub
  ```

- [ ] **Add keg-only PATH exports** to `~/.zshrc` (the setup script prints the
  exact lines at the end of its run)

- [ ] **Enable VS Code Settings Sync** (`Cmd+Shift+P` -> "Settings Sync: Turn On")

- [ ] **Docker Desktop**: Images don't transfer between machines. Pull or build
  your images fresh on the Mac.

- [ ] **Transfer Obsidian vault** data via Syncthing, iCloud, or manual copy

- [ ] **Authenticate Claude Code** — run `claude` in terminal and sign in

- [ ] **Sign into Claude Desktop** — open the app and log in

- [ ] **Review Claude hooks** — check `~/.claude/settings.json` for any paths
  specific to your Windows layout (homelab-infra, Obsidian Vault location, etc.)

- [ ] **Set macOS developer defaults** (optional quality-of-life tweaks):
  ```bash
  # Show hidden files in Finder
  defaults write com.apple.finder AppleShowAllFiles -bool true

  # Fast key repeat rate
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15

  # Show file extensions
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true

  # Restart Finder to apply
  killall Finder
  ```
