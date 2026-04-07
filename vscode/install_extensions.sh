#!/bin/bash
# =============================================================================
# Install VS Code Extensions from vscode_extensions.txt
# =============================================================================
# Reads each extension ID and installs it. Skips Windows-only extensions.
# Tracks and reports failures without aborting.
#
# Usage:
#   bash vscode/install_extensions.sh
#   (or called automatically by scripts/full_setup.sh)
# =============================================================================

# Resolve paths relative to this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EXTENSIONS_FILE="$SCRIPT_DIR/vscode_extensions.txt"

# Windows-only extensions to skip on macOS
SKIP_LIST=(
    "ms-vscode-remote.remote-wsl"
)

# ---------------------------------------------------------------------------
# Pre-flight: check that 'code' is available
# ---------------------------------------------------------------------------
if ! command -v code &> /dev/null; then
    echo "ERROR: 'code' command not found in PATH."
    echo ""
    echo "Possible fixes:"
    echo "  1. Install VS Code first: brew install --cask visual-studio-code"
    echo "  2. Open VS Code, press Cmd+Shift+P, type 'Shell Command: Install'"
    echo "     to add 'code' to your PATH."
    exit 1
fi

# ---------------------------------------------------------------------------
# Check extensions file exists
# ---------------------------------------------------------------------------
if [[ ! -f "$EXTENSIONS_FILE" ]]; then
    echo "ERROR: Extensions file not found at: $EXTENSIONS_FILE"
    echo "Run scan_windows.ps1 on your Windows machine first, or ensure"
    echo "vscode_extensions.txt is in the vscode/ directory."
    exit 1
fi

# ---------------------------------------------------------------------------
# Install extensions
# ---------------------------------------------------------------------------
installed=0
skipped=0
failed=0
failed_list=()

total=$(grep -c -v -e '^$' -e '^#' "$EXTENSIONS_FILE" 2>/dev/null || echo 0)
current=0

echo "Installing VS Code extensions ($total found)..."
echo ""

while IFS= read -r extension || [[ -n "$extension" ]]; do
    # Skip blank lines and comments
    [[ -z "$extension" || "$extension" =~ ^# ]] && continue

    # Trim whitespace
    extension="$(echo "$extension" | xargs)"

    current=$((current + 1))

    # Check skip list
    skip=false
    for s in "${SKIP_LIST[@]}"; do
        if [[ "$extension" == "$s" ]]; then
            skip=true
            break
        fi
    done

    if $skip; then
        echo "  [$current/$total] SKIP  $extension (Windows-only)"
        skipped=$((skipped + 1))
        continue
    fi

    # Install the extension
    echo -n "  [$current/$total] Installing $extension... "
    if code --install-extension "$extension" --force > /dev/null 2>&1; then
        echo "OK"
        installed=$((installed + 1))
    else
        echo "FAILED"
        failed=$((failed + 1))
        failed_list+=("$extension")
    fi

done < "$EXTENSIONS_FILE"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo " VS Code Extensions — Summary"
echo "============================================"
echo "  Installed:  $installed"
echo "  Skipped:    $skipped (Windows-only)"
echo "  Failed:     $failed"

if [[ $failed -gt 0 ]]; then
    echo ""
    echo "  Failed extensions:"
    for ext in "${failed_list[@]}"; do
        echo "    - $ext"
    done
    echo ""
    echo "  These may be deprecated or renamed. Search the VS Code marketplace"
    echo "  manually: https://marketplace.visualstudio.com/"
fi

echo ""
