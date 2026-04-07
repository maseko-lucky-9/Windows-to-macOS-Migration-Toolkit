#Requires -Version 5.1
<#
.SYNOPSIS
    Exports installed applications, VS Code extensions, npm globals, and git
    config from a Windows machine for migration to macOS.

.DESCRIPTION
    Run this script from the mac-migration/scripts/ directory (or anywhere —
    paths resolve relative to the script location). Output files land in the
    repo's apps/ and vscode/ directories.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scan_windows.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# ---------------------------------------------------------------------------
# Resolve paths relative to repo root
# ---------------------------------------------------------------------------
$RepoRoot = Split-Path -Parent $PSScriptRoot   # one level up from scripts/
$AppsDir  = Join-Path $RepoRoot 'apps'
$VsDir    = Join-Path $RepoRoot 'vscode'

# Ensure output directories exist
New-Item -ItemType Directory -Path $AppsDir -Force | Out-Null
New-Item -ItemType Directory -Path $VsDir   -Force | Out-Null

$summary = @()

# ---------------------------------------------------------------------------
# 1. Registry — Add/Remove Programs
# ---------------------------------------------------------------------------
Write-Host "`n[1/5] Scanning installed programs from registry..." -ForegroundColor Cyan

$regPaths = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
)

$registryApps = $regPaths | ForEach-Object {
    Get-ItemProperty $_ -ErrorAction SilentlyContinue
} | Where-Object { $_.PSObject.Properties['DisplayName'] -and $_.DisplayName } |
    Select-Object DisplayName, DisplayVersion, Publisher |
    Sort-Object DisplayName -Unique

$outRegistry = Join-Path $AppsDir 'windows_apps_raw.txt'

# Start the file with the registry section
"# === Registry (Add/Remove Programs) ===" | Out-File $outRegistry -Encoding UTF8
"# Exported: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File $outRegistry -Append -Encoding UTF8
"" | Out-File $outRegistry -Append -Encoding UTF8
$registryApps | Format-Table -AutoSize | Out-String | Out-File $outRegistry -Append -Encoding UTF8

$regCount = ($registryApps | Measure-Object).Count
$summary += "  Registry apps:       $regCount entries -> $outRegistry"

# ---------------------------------------------------------------------------
# 2. winget list (supplementary)
# ---------------------------------------------------------------------------
Write-Host "[2/5] Running winget list..." -ForegroundColor Cyan

if (Get-Command winget -ErrorAction SilentlyContinue) {
    "" | Out-File $outRegistry -Append -Encoding UTF8
    "# === winget list ===" | Out-File $outRegistry -Append -Encoding UTF8
    "" | Out-File $outRegistry -Append -Encoding UTF8
    $wingetOutput = winget list --disable-interactivity 2>&1
    $wingetOutput | Out-File $outRegistry -Append -Encoding UTF8
    $summary += "  winget list:         appended to $outRegistry"
} else {
    $summary += "  winget list:         SKIPPED (winget not found)"
}

# ---------------------------------------------------------------------------
# 3. VS Code extensions
# ---------------------------------------------------------------------------
Write-Host "[3/5] Exporting VS Code extensions..." -ForegroundColor Cyan

$outExtensions = Join-Path $VsDir 'vscode_extensions.txt'

if (Get-Command code -ErrorAction SilentlyContinue) {
    $extensions = code --list-extensions 2>&1
    $extensions | Out-File $outExtensions -Encoding UTF8
    $extCount = ($extensions | Measure-Object -Line).Lines
    $summary += "  VS Code extensions:  $extCount extensions -> $outExtensions"
} else {
    $summary += "  VS Code extensions:  SKIPPED (code not in PATH)"
}

# ---------------------------------------------------------------------------
# 4. npm global packages
# ---------------------------------------------------------------------------
Write-Host "[4/5] Exporting npm global packages..." -ForegroundColor Cyan

$outNpm = Join-Path $AppsDir 'npm_globals.txt'

if (Get-Command npm -ErrorAction SilentlyContinue) {
    $npmOutput = npm list -g --depth=0 2>&1
    $npmOutput | Out-File $outNpm -Encoding UTF8
    $npmCount = ($npmOutput | Where-Object { $_ -match '^\+--' } | Measure-Object).Count
    $summary += "  npm globals:         $npmCount packages -> $outNpm"
} else {
    $summary += "  npm globals:         SKIPPED (npm not in PATH)"
}

# ---------------------------------------------------------------------------
# 5. Git global config
# ---------------------------------------------------------------------------
Write-Host "[5/5] Exporting git global config..." -ForegroundColor Cyan

$outGit = Join-Path $AppsDir 'git_config.txt'

if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitConfig = git config --global --list 2>&1
    $gitConfig | Out-File $outGit -Encoding UTF8
    $gitLines = ($gitConfig | Measure-Object -Line).Lines
    $summary += "  git config:          $gitLines settings -> $outGit"
} else {
    $summary += "  git config:          SKIPPED (git not in PATH)"
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host "`n============================================" -ForegroundColor Green
Write-Host " Export complete!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
$summary | ForEach-Object { Write-Host $_ }
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review the generated files in apps/ and vscode/"
Write-Host "  2. Commit and push this repo (or transfer to your Mac)"
Write-Host "  3. On your Mac, run: bash scripts/full_setup.sh"
Write-Host ""
