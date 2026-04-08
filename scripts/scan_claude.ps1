#Requires -Version 5.1
<#
.SYNOPSIS
    Exports Claude Code and Claude Desktop configuration from Windows
    for migration to macOS.

.DESCRIPTION
    Copies portable Claude configuration into the repo's claude/ directory.
    Run alongside scan_windows.ps1 before transferring the repo to your Mac.

    Exported:
      - settings.json, CLAUDE.md, .claudeignore (core config)
      - agents/*.agent.md (custom agent definitions)
      - reference/*.md (reference documents)
      - projects/*/memory/*.md (project-level memories)
      - claude_desktop_config.json (Desktop app preferences)

    Skipped (ephemeral/platform-specific):
      - sessions, cache, logs, plugins, skills, audit.log, history.jsonl

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scan_claude.ps1
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'

# ---------------------------------------------------------------------------
# Resolve paths
# ---------------------------------------------------------------------------
$RepoRoot       = Split-Path -Parent $PSScriptRoot
$ClaudeHome     = Join-Path $env:USERPROFILE '.claude'
$DesktopAppData = Join-Path $env:APPDATA 'Claude'
$OutDir         = Join-Path $RepoRoot 'claude'

# Ensure output directory exists
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

$summary = @()
$totalFiles = 0

# ---------------------------------------------------------------------------
# 1/4  Core config files
# ---------------------------------------------------------------------------
Write-Host "`n[1/4] Exporting core config files..." -ForegroundColor Cyan

$coreFiles = @(
    @{ Src = 'settings.json'; Dst = 'settings.json' },
    @{ Src = 'CLAUDE.md';     Dst = 'CLAUDE.md' },
    @{ Src = '.claudeignore';  Dst = '.claudeignore' },
    @{ Src = 'SKILLS.md';     Dst = 'SKILLS.md' }
)

$coreCount = 0
foreach ($f in $coreFiles) {
    $srcPath = Join-Path $ClaudeHome $f.Src
    $dstPath = Join-Path $OutDir $f.Dst
    if (Test-Path $srcPath) {
        Copy-Item $srcPath $dstPath -Force
        $coreCount++
        Write-Host "  Copied $($f.Src)"
    } else {
        Write-Host "  SKIP  $($f.Src) (not found)" -ForegroundColor Yellow
    }
}
$totalFiles += $coreCount
$summary += "  Core config:         $coreCount files"

# ---------------------------------------------------------------------------
# 2/4  Agents and reference docs
# ---------------------------------------------------------------------------
Write-Host "[2/4] Exporting agents and reference docs..." -ForegroundColor Cyan

# Agents
$agentSrc = Join-Path $ClaudeHome 'agents'
$agentDst = Join-Path $OutDir 'agents'
$agentCount = 0

if (Test-Path $agentSrc) {
    New-Item -ItemType Directory -Path $agentDst -Force | Out-Null

    # Copy .agent.md files from root of agents/ (skip archive/ subdir)
    Get-ChildItem -Path $agentSrc -Filter '*.agent.md' -File | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $agentDst $_.Name) -Force
        $agentCount++
    }

    # Copy AGENTS.md if present
    $agentsMdPath = Join-Path $agentSrc 'AGENTS.md'
    if (Test-Path $agentsMdPath) {
        Copy-Item $agentsMdPath (Join-Path $agentDst 'AGENTS.md') -Force
        $agentCount++
    }
}
$totalFiles += $agentCount
$summary += "  Agents:              $agentCount files"

# Reference docs
$refSrc = Join-Path $ClaudeHome 'reference'
$refDst = Join-Path $OutDir 'reference'
$refCount = 0

if (Test-Path $refSrc) {
    New-Item -ItemType Directory -Path $refDst -Force | Out-Null

    # Copy .md files from root of reference/
    Get-ChildItem -Path $refSrc -Filter '*.md' -File | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $refDst $_.Name) -Force
        $refCount++
    }

    # Copy subdirectories (e.g., scripts/) with all contents
    Get-ChildItem -Path $refSrc -Directory | ForEach-Object {
        $subDst = Join-Path $refDst $_.Name
        Copy-Item $_.FullName $subDst -Recurse -Force
        $subCount = (Get-ChildItem $subDst -File -Recurse | Measure-Object).Count
        $refCount += $subCount
    }
}
$totalFiles += $refCount
$summary += "  Reference docs:      $refCount files"

# ---------------------------------------------------------------------------
# 3/4  Project memories
# ---------------------------------------------------------------------------
Write-Host "[3/4] Exporting project memories..." -ForegroundColor Cyan

$projectsSrc = Join-Path $ClaudeHome 'projects'
$projectsDst = Join-Path $OutDir 'projects'
$projCount = 0
$memFileCount = 0

if (Test-Path $projectsSrc) {
    Get-ChildItem -Path $projectsSrc -Directory | ForEach-Object {
        $memDir = Join-Path $_.FullName 'memory'
        if ((Test-Path $memDir) -and (Get-ChildItem $memDir -Filter '*.md' -File -ErrorAction SilentlyContinue)) {
            $projName  = $_.Name
            $dstMemDir = Join-Path $projectsDst "$projName\memory"
            New-Item -ItemType Directory -Path $dstMemDir -Force | Out-Null

            Get-ChildItem $memDir -Filter '*.md' -File | ForEach-Object {
                Copy-Item $_.FullName (Join-Path $dstMemDir $_.Name) -Force
                $memFileCount++
            }
            $projCount++
        }
    }
}
$totalFiles += $memFileCount
$summary += "  Project memories:    $memFileCount files across $projCount projects"

# ---------------------------------------------------------------------------
# 4/4  Claude Desktop config
# ---------------------------------------------------------------------------
Write-Host "[4/4] Exporting Claude Desktop config..." -ForegroundColor Cyan

$desktopConfig = Join-Path $DesktopAppData 'claude_desktop_config.json'
$desktopCount = 0

if (Test-Path $desktopConfig) {
    Copy-Item $desktopConfig (Join-Path $OutDir 'claude_desktop_config.json') -Force
    $desktopCount = 1
    Write-Host "  Copied claude_desktop_config.json"
} else {
    Write-Host "  SKIP  claude_desktop_config.json (not found)" -ForegroundColor Yellow
}
$totalFiles += $desktopCount
$summary += "  Desktop config:      $desktopCount file"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
Write-Host "`n============================================" -ForegroundColor Green
Write-Host " Claude config export complete! ($totalFiles files)" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
$summary | ForEach-Object { Write-Host $_ }
Write-Host ""
Write-Host "Output directory: $OutDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review exported files in claude/"
Write-Host "  2. Commit and transfer the repo to your Mac"
Write-Host "  3. On your Mac, run: bash scripts/full_setup.sh"
Write-Host "     (Stage 10 handles Claude config migration automatically)"
Write-Host ""
