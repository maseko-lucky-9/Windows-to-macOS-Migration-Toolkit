#!/bin/bash
# =============================================================================
# macOS Full Setup — Windows Migration
# =============================================================================
# One-shot script that installs Homebrew, all applications from brew_apps.txt,
# global npm packages (Claude Code), and VS Code extensions.
#
# Usage:
#   bash scripts/full_setup.sh
#
# Safe to re-run — brew and code skip already-installed items.
# =============================================================================

# ---------------------------------------------------------------------------
# Path resolution
# ---------------------------------------------------------------------------
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$SCRIPT_DIR/.."
BREW_APPS="$REPO_ROOT/apps/brew_apps.txt"
EXTENSIONS_SCRIPT="$REPO_ROOT/vscode/install_extensions.sh"
CLAUDE_MIGRATE="$SCRIPT_DIR/migrate_claude.sh"

# ---------------------------------------------------------------------------
# Tracking arrays for summary
# ---------------------------------------------------------------------------
brew_success=0
brew_fail=0
brew_failed_list=()
keg_only_formulas=()
stage_results=()

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
print_header() {
    echo ""
    echo "============================================"
    echo " $1"
    echo "============================================"
}

print_step() {
    echo ""
    echo "--- [$1] $2 ---"
}

# ---------------------------------------------------------------------------
# Stage 1: macOS check
# ---------------------------------------------------------------------------
print_step "1/10" "Verifying macOS"

if [[ "$(uname)" != "Darwin" ]]; then
    echo "ERROR: This script must be run on macOS, not $(uname)."
    echo "On Windows, run scripts/scan_windows.ps1 instead."
    exit 1
fi

echo "OK — macOS $(sw_vers -productVersion) detected."
stage_results+=("macOS check: PASS")

# ---------------------------------------------------------------------------
# Stage 2: Xcode Command Line Tools
# ---------------------------------------------------------------------------
print_step "2/10" "Checking Xcode Command Line Tools"

if xcode-select -p &> /dev/null; then
    echo "OK — already installed at $(xcode-select -p)"
else
    echo "Xcode CLI tools not found. Installing..."
    echo "(A dialog may appear — click 'Install' and wait for it to finish.)"
    xcode-select --install

    # Wait for installation to complete
    echo "Waiting for Xcode CLI tools installation..."
    until xcode-select -p &> /dev/null; do
        sleep 5
    done
    echo "OK — installed."
fi
stage_results+=("Xcode CLI tools: PASS")

# ---------------------------------------------------------------------------
# Stage 3: Rosetta 2 (Apple Silicon only)
# ---------------------------------------------------------------------------
print_step "3/10" "Checking Rosetta 2"

if [[ "$(uname -m)" == "arm64" ]]; then
    if /usr/bin/pgrep -q oahd; then
        echo "OK — Rosetta 2 already installed."
    else
        echo "Apple Silicon detected. Installing Rosetta 2..."
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
        echo "OK — installed."
    fi
else
    echo "SKIP — Intel Mac detected, Rosetta 2 not needed."
fi
stage_results+=("Rosetta 2: PASS")

# ---------------------------------------------------------------------------
# Stage 4: Homebrew
# ---------------------------------------------------------------------------
print_step "4/10" "Checking Homebrew"

if command -v brew &> /dev/null; then
    echo "OK — Homebrew already installed at $(which brew)"
else
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Source brew shellenv for this session (handles both ARM and Intel paths)
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

if ! command -v brew &> /dev/null; then
    echo "ERROR: Homebrew installation failed or not in PATH."
    echo "Try running the install command manually from https://brew.sh"
    exit 1
fi

echo "Homebrew $(brew --version | head -1) ready."
stage_results+=("Homebrew: PASS")

# ---------------------------------------------------------------------------
# Stage 5: brew update
# ---------------------------------------------------------------------------
print_step "5/10" "Updating Homebrew"

brew update
echo "OK — Homebrew updated."
stage_results+=("brew update: PASS")

# ---------------------------------------------------------------------------
# Stage 6: Install applications from brew_apps.txt
# ---------------------------------------------------------------------------
print_step "6/10" "Installing applications from brew_apps.txt"

if [[ ! -f "$BREW_APPS" ]]; then
    echo "WARNING: $BREW_APPS not found. Skipping brew installs."
    stage_results+=("brew apps: SKIPPED (file not found)")
else
    total=$(grep -c -E '^brew install' "$BREW_APPS" 2>/dev/null || echo 0)
    current=0

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip blank lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        current=$((current + 1))

        # Extract the package name for display
        pkg=$(echo "$line" | awk '{print $NF}')

        echo -n "  [$current/$total] $line ... "
        if eval "$line" > /dev/null 2>&1; then
            echo "OK"
            brew_success=$((brew_success + 1))
        else
            echo "FAILED"
            brew_fail=$((brew_fail + 1))
            brew_failed_list+=("$line")
        fi

        # Track keg-only formulas (versioned formulas are typically keg-only)
        if [[ "$line" =~ brew\ install\ [^-] ]] && [[ "$pkg" =~ @ ]]; then
            keg_only_formulas+=("$pkg")
        fi

    done < "$BREW_APPS"

    stage_results+=("brew apps: $brew_success OK, $brew_fail failed")
fi

# ---------------------------------------------------------------------------
# Stage 7: Add keg-only formulas to PATH for this session
# ---------------------------------------------------------------------------
print_step "7/10" "Linking keg-only formulas to PATH"

if [[ ${#keg_only_formulas[@]} -gt 0 ]]; then
    for formula in "${keg_only_formulas[@]}"; do
        prefix=$(brew --prefix "$formula" 2>/dev/null)
        if [[ -n "$prefix" && -d "$prefix/bin" ]]; then
            export PATH="$prefix/bin:$PATH"
            echo "  Added $prefix/bin to PATH"
        fi
    done
    echo "OK — keg-only formulas available for this session."
else
    echo "SKIP — no keg-only formulas detected."
fi
stage_results+=("keg-only PATH: PASS")

# ---------------------------------------------------------------------------
# Stage 8: Install Claude Code via npm
# ---------------------------------------------------------------------------
print_step "8/10" "Installing Claude Code (npm)"

if command -v npm &> /dev/null; then
    echo -n "  npm install -g @anthropic-ai/claude-code ... "
    if npm install -g @anthropic-ai/claude-code > /dev/null 2>&1; then
        echo "OK"
        stage_results+=("Claude Code (npm): PASS")
    else
        echo "FAILED"
        stage_results+=("Claude Code (npm): FAILED")
    fi
else
    echo "WARNING: npm not found. Install Node.js first, then run:"
    echo "  npm install -g @anthropic-ai/claude-code"
    stage_results+=("Claude Code (npm): SKIPPED (npm not in PATH)")
fi

# ---------------------------------------------------------------------------
# Stage 9: Install VS Code extensions
# ---------------------------------------------------------------------------
print_step "9/10" "Installing VS Code extensions"

if [[ -f "$EXTENSIONS_SCRIPT" ]]; then
    bash "$EXTENSIONS_SCRIPT"
    stage_results+=("VS Code extensions: DONE (see above)")
else
    echo "WARNING: $EXTENSIONS_SCRIPT not found. Skipping."
    stage_results+=("VS Code extensions: SKIPPED (script not found)")
fi

# ---------------------------------------------------------------------------
# Stage 10: Migrate Claude Code & Desktop configuration
# ---------------------------------------------------------------------------
print_step "10/10" "Migrating Claude Code & Desktop configuration"

if [[ -d "$REPO_ROOT/claude" ]]; then
    if [[ -f "$CLAUDE_MIGRATE" ]]; then
        CLAUDE_MIGRATE_QUIET=1 bash "$CLAUDE_MIGRATE"
        stage_results+=("Claude config: DONE (see above)")
    else
        echo "WARNING: $CLAUDE_MIGRATE not found. Skipping."
        stage_results+=("Claude config: SKIPPED (migrate script not found)")
    fi
else
    echo "SKIP — no claude/ directory in repo. Run scan_claude.ps1 on Windows first."
    stage_results+=("Claude config: SKIPPED (no claude/ export)")
fi

# =============================================================================
# Final Summary
# =============================================================================
print_header "Setup Complete — Summary"

for result in "${stage_results[@]}"; do
    echo "  $result"
done

if [[ $brew_fail -gt 0 ]]; then
    echo ""
    echo "  Failed brew installs ($brew_fail):"
    for item in "${brew_failed_list[@]}"; do
        echo "    - $item"
    done
fi

# ---------------------------------------------------------------------------
# Post-setup: keg-only PATH instructions for .zshrc
# ---------------------------------------------------------------------------
if [[ ${#keg_only_formulas[@]} -gt 0 ]]; then
    echo ""
    print_header "ACTION REQUIRED: Add to ~/.zshrc"
    echo ""
    echo "The following formulas are keg-only (not symlinked to /usr/local)."
    echo "Add these lines to your ~/.zshrc for persistent PATH access:"
    echo ""
    for formula in "${keg_only_formulas[@]}"; do
        prefix=$(brew --prefix "$formula" 2>/dev/null)
        if [[ -n "$prefix" ]]; then
            echo "  export PATH=\"$prefix/bin:\$PATH\""
        fi
    done
    echo ""
    echo "Then reload your shell:  source ~/.zshrc"
fi

# ---------------------------------------------------------------------------
# Post-migration checklist
# ---------------------------------------------------------------------------
echo ""
print_header "Post-Migration Checklist"
echo ""
echo "  [ ] Configure git identity:"
echo "        git config --global user.name \"Your Name\""
echo "        git config --global user.email \"you@example.com\""
echo "        (Reference: apps/git_config.txt from your Windows export)"
echo ""
echo "  [ ] Generate SSH keys for GitHub:"
echo "        ssh-keygen -t ed25519 -C \"you@example.com\""
echo "        Then add ~/.ssh/id_ed25519.pub to https://github.com/settings/keys"
echo ""
echo "  [ ] Enable VS Code Settings Sync:"
echo "        Open VS Code -> Cmd+Shift+P -> 'Settings Sync: Turn On'"
echo ""
echo "  [ ] Docker Desktop: pull/build images fresh (they don't transfer)"
echo ""
echo "  [ ] Transfer Obsidian vault data (Syncthing, iCloud, or manual copy)"
echo ""
echo "  [ ] Authenticate Claude Code: run 'claude' and follow the sign-in flow"
echo ""
echo "  [ ] Sign into Claude Desktop (open the app and log in)"
echo ""
echo "  [ ] Review hooks in ~/.claude/settings.json for platform-specific paths"
echo ""
