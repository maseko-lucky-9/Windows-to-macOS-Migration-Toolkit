#!/bin/bash
# =============================================================================
# Claude Code & Desktop — Configuration Migration (Windows → macOS)
# =============================================================================
# Deploys exported Claude configs from the repo's claude/ directory to the
# correct macOS locations with automatic path transformation.
#
# Called by full_setup.sh (Stage 10) or run standalone:
#   bash scripts/migrate_claude.sh
#
# What it does:
#   1. Copies settings.json, CLAUDE.md, .claudeignore to ~/.claude/
#   2. Copies agents/*.agent.md and reference/*.md to ~/.claude/
#   3. Remaps project memory directories (strips Windows drive prefix)
#   4. Deploys Claude Desktop config to ~/Library/Application Support/Claude/
#   5. Performs path surgery on all config files:
#        C:/Users/<win_user>/  →  /Users/$USER/
#        C:\\Users\\<win_user>\\  →  /Users/$USER/
#        //c/Users/<win_user>/  →  /Users/$USER/
#
# Safe to re-run — overwrites existing config with latest export.
# =============================================================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$SCRIPT_DIR/.."
CLAUDE_EXPORT="$REPO_ROOT/claude"
CLAUDE_HOME="$HOME/.claude"
DESKTOP_CONFIG_DIR="$HOME/Library/Application Support/Claude"

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
if [[ ! -d "$CLAUDE_EXPORT" ]]; then
    echo "ERROR: claude/ directory not found in repo root."
    echo "Run scan_claude.ps1 on Windows first to export your config."
    exit 1
fi

if [[ "$(uname)" != "Darwin" ]]; then
    echo "ERROR: This script must be run on macOS."
    exit 1
fi

# ---------------------------------------------------------------------------
# Detect Windows username from exported settings.json
# ---------------------------------------------------------------------------
WIN_USER=""
if [[ -f "$CLAUDE_EXPORT/settings.json" ]]; then
    WIN_USER=$(grep -oE 'C:/Users/[^/]+' "$CLAUDE_EXPORT/settings.json" | head -1 | sed 's|C:/Users/||')
fi

if [[ -z "$WIN_USER" ]]; then
    echo "WARNING: Could not detect Windows username from settings.json."
    echo "Path replacement will be skipped — you may need to update paths manually."
fi

MAC_USER="$USER"

echo "Migrating Claude config: Windows user '$WIN_USER' → macOS user '$MAC_USER'"
echo ""

# ---------------------------------------------------------------------------
# Helper: apply path surgery to a file
# ---------------------------------------------------------------------------
apply_path_surgery() {
    local file="$1"

    if [[ -z "$WIN_USER" ]]; then
        return
    fi

    # Forward-slash paths: C:/Users/ltmas/ → /Users/$MAC_USER/
    sed -i '' "s|C:/Users/$WIN_USER/|/Users/$MAC_USER/|g" "$file"

    # Double-backslash paths (JSON): C:\\Users\\ltmas\\ → /Users/$MAC_USER/
    sed -i '' "s|C:\\\\\\\\Users\\\\\\\\$WIN_USER\\\\\\\\|/Users/$MAC_USER/|g" "$file"

    # Git Bash paths: //c/Users/ltmas/ → /Users/$MAC_USER/
    sed -i '' "s|//c/Users/$WIN_USER/|/Users/$MAC_USER/|g" "$file"

    # Case-insensitive drive letter variants: c:/Users/... and c--Users-...
    sed -i '' "s|c:/Users/$WIN_USER/|/Users/$MAC_USER/|g" "$file"
}

# ---------------------------------------------------------------------------
# 1/5  Core config files
# ---------------------------------------------------------------------------
echo "[1/5] Deploying core config files..."

mkdir -p "$CLAUDE_HOME"
core_count=0

for f in settings.json CLAUDE.md .claudeignore SKILLS.md; do
    src="$CLAUDE_EXPORT/$f"
    dst="$CLAUDE_HOME/$f"
    if [[ -f "$src" ]]; then
        # Backup existing file before overwrite
        if [[ -f "$dst" ]]; then
            cp "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
        fi
        cp "$src" "$dst"
        apply_path_surgery "$dst"
        echo "  Deployed $f"
        core_count=$((core_count + 1))
    fi
done

echo "  $core_count core files deployed."

# ---------------------------------------------------------------------------
# 2/5  Agents
# ---------------------------------------------------------------------------
echo "[2/5] Deploying custom agents..."

agent_count=0
if [[ -d "$CLAUDE_EXPORT/agents" ]]; then
    mkdir -p "$CLAUDE_HOME/agents"
    for f in "$CLAUDE_EXPORT/agents/"*; do
        [[ -f "$f" ]] || continue
        cp "$f" "$CLAUDE_HOME/agents/"
        agent_count=$((agent_count + 1))
    done
fi

echo "  $agent_count agent files deployed."

# ---------------------------------------------------------------------------
# 3/5  Reference docs
# ---------------------------------------------------------------------------
echo "[3/5] Deploying reference docs..."

ref_count=0
if [[ -d "$CLAUDE_EXPORT/reference" ]]; then
    mkdir -p "$CLAUDE_HOME/reference"
    for f in "$CLAUDE_EXPORT/reference/"*.md; do
        [[ -f "$f" ]] || continue
        cp "$f" "$CLAUDE_HOME/reference/"
        ref_count=$((ref_count + 1))
    done

    # Copy reference subdirectories (e.g., scripts/)
    for subdir in "$CLAUDE_EXPORT/reference/"*/; do
        [[ -d "$subdir" ]] || continue
        sub_name=$(basename "$subdir")
        mkdir -p "$CLAUDE_HOME/reference/$sub_name"
        cp -R "$subdir"* "$CLAUDE_HOME/reference/$sub_name/" 2>/dev/null
        sub_count=$(find "$subdir" -type f | wc -l | tr -d ' ')
        ref_count=$((ref_count + sub_count))
    done
fi

echo "  $ref_count reference files deployed."

# ---------------------------------------------------------------------------
# 4/5  Project memories (with directory name remapping)
# ---------------------------------------------------------------------------
echo "[4/5] Deploying project memories..."

proj_count=0
mem_count=0
unmapped_dirs=()

if [[ -d "$CLAUDE_EXPORT/projects" ]]; then
    for proj_dir in "$CLAUDE_EXPORT/projects/"*/; do
        [[ -d "$proj_dir" ]] || continue

        mem_src="$proj_dir/memory"
        [[ -d "$mem_src" ]] || continue

        # Remap directory name: strip Windows drive prefix, swap username
        dir_name=$(basename "$proj_dir")

        # Strip C-- or c-- drive prefix
        new_name=$(echo "$dir_name" | sed -E 's/^[Cc]--//')

        # Replace Windows username with macOS username in dir name
        if [[ -n "$WIN_USER" ]]; then
            new_name=$(echo "$new_name" | sed "s/$WIN_USER/$MAC_USER/g")
        fi

        # Warn about dirs that don't follow the Users-<user>-... pattern
        if [[ -n "$WIN_USER" ]] && ! echo "$dir_name" | grep -qi "Users-$WIN_USER"; then
            unmapped_dirs+=("$dir_name → $new_name")
        fi

        dst_mem="$CLAUDE_HOME/projects/$new_name/memory"
        mkdir -p "$dst_mem"

        for mem_file in "$mem_src/"*.md; do
            [[ -f "$mem_file" ]] || continue
            cp "$mem_file" "$dst_mem/"
            apply_path_surgery "$dst_mem/$(basename "$mem_file")"
            mem_count=$((mem_count + 1))
        done
        proj_count=$((proj_count + 1))
    done
fi

echo "  $mem_count memory files across $proj_count projects."

if [[ ${#unmapped_dirs[@]} -gt 0 ]]; then
    echo ""
    echo "  WARNING: These project dirs may not map correctly to macOS paths."
    echo "  Claude Code generates dir names from the project's absolute path."
    echo "  After opening these projects on macOS, manually copy memories to"
    echo "  the directory Claude Code creates:"
    for d in "${unmapped_dirs[@]}"; do
        echo "    - $d"
    done
fi

# ---------------------------------------------------------------------------
# 5/5  Claude Desktop config
# ---------------------------------------------------------------------------
echo "[5/5] Deploying Claude Desktop config..."

desktop_ok=0
if [[ -f "$CLAUDE_EXPORT/claude_desktop_config.json" ]]; then
    mkdir -p "$DESKTOP_CONFIG_DIR"
    # Backup existing Desktop config
    local_dst="$DESKTOP_CONFIG_DIR/claude_desktop_config.json"
    if [[ -f "$local_dst" ]]; then
        cp "$local_dst" "$local_dst.bak.$(date +%Y%m%d%H%M%S)"
    fi
    cp "$CLAUDE_EXPORT/claude_desktop_config.json" "$local_dst"
    apply_path_surgery "$local_dst"
    desktop_ok=1
    echo "  Deployed claude_desktop_config.json"
else
    echo "  SKIP — no Desktop config exported."
fi

# ---------------------------------------------------------------------------
# Post-surgery validation: check for residual Windows paths
# ---------------------------------------------------------------------------
residual_files=()
for check_file in "$CLAUDE_HOME/settings.json" "$CLAUDE_HOME/CLAUDE.md" "$DESKTOP_CONFIG_DIR/claude_desktop_config.json"; do
    if [[ -f "$check_file" ]] && grep -qE 'C:/Users/|C:\\\\Users\\\\|//c/Users/' "$check_file" 2>/dev/null; then
        residual_files+=("$(basename "$check_file")")
    fi
done

# =============================================================================
# Summary
# =============================================================================
echo ""
echo "============================================"
echo " Claude config migration complete!"
echo "============================================"
echo ""
echo "  Core config:       $core_count files"
echo "  Agents:            $agent_count files"
echo "  Reference docs:    $ref_count files"
echo "  Project memories:  $mem_count files ($proj_count projects)"
echo "  Desktop config:    $desktop_ok file"

if [[ ${#residual_files[@]} -gt 0 ]]; then
    echo ""
    echo "  WARNING: Residual Windows paths found in:"
    for rf in "${residual_files[@]}"; do
        echo "    - $rf"
    done
    echo "  Run: grep -n 'C:/Users' ~/.claude/settings.json  to find them."
fi
echo ""

# ---------------------------------------------------------------------------
# Post-migration warnings (suppressed when called from full_setup.sh)
# ---------------------------------------------------------------------------
if [[ -z "${CLAUDE_MIGRATE_QUIET:-}" ]]; then
    echo "============================================"
    echo " Review Required"
    echo "============================================"
    echo ""
    echo "  The following items may need manual attention:"
    echo ""
    echo "  1. HOOKS: Review ~/.claude/settings.json hooks for paths that"
    echo "     reference Windows-specific locations (homelab-infra, Obsidian Vault)."
    echo "     The path prefixes were updated, but verify they match your Mac layout."
    echo ""
    echo "  2. PERMISSIONS: The allow-list in settings.json was path-updated."
    echo "     Verify the directories exist on your Mac (e.g., ~/Repo, ~/Documents)."
    echo ""
    echo "  3. AUTHENTICATION: You must sign in manually:"
    echo "     - Claude Code:    run 'claude' in terminal and follow the auth flow"
    echo "     - Claude Desktop: open the app and sign in"
    echo ""
    echo "  4. PLUGINS & SKILLS: These reinstall automatically from the marketplace"
    echo "     on first use. No manual action needed."
    echo ""
fi
