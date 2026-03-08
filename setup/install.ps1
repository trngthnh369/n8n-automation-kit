<#
.SYNOPSIS
    n8n Automation Kit Installer for Windows
.DESCRIPTION
    Installs the n8n Automation Kit to the appropriate directory for your AI agent.
.PARAMETER Agent
    Target agent platform: antigravity, claude, gemini, cursor, auto (default: auto)
.PARAMETER TargetDir
    Custom target directory (overrides auto-detection)
.PARAMETER Tiers
    Comma-separated tiers to install: all, 1, 2, 3, 4 (default: all)
.EXAMPLE
    .\install.ps1 -Agent antigravity
    .\install.ps1 -Agent claude -Tiers "1,2,3"
    .\install.ps1 -TargetDir "D:\MyProject\.agents\skills\n8n-automation-kit"
#>
param(
    [string]$Agent = "auto",
    [string]$TargetDir = "",
    [string]$Tiers = "all"
)

$ErrorActionPreference = "Stop"
$KitVersion = "1.0.0"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$KitRoot = Split-Path -Parent $ScriptDir

Write-Host ""
Write-Host "=== n8n Automation Kit Installer v$KitVersion ===" -ForegroundColor Cyan
Write-Host ""

# --- Agent Detection ---
function Detect-Agent {
    # Check for Antigravity/Gemini
    if (Test-Path ".\.agents") { return "antigravity" }
    if (Test-Path ".\.agent") { return "antigravity" }
    
    # Check for Claude Code
    if (Test-Path "$env:USERPROFILE\.claude") { return "claude" }
    
    # Check for Cursor
    if (Test-Path ".\.cursor") { return "cursor" }
    
    # Default
    return "antigravity"
}

if ($Agent -eq "auto") {
    $Agent = Detect-Agent
    Write-Host "Auto-detected agent: $Agent" -ForegroundColor Yellow
}

# --- Target Directory ---
if ($TargetDir -eq "") {
    switch ($Agent) {
        "antigravity" { $TargetDir = ".\.agents\skills\n8n-automation-kit" }
        "gemini"      { $TargetDir = ".\.agents\skills\n8n-automation-kit" }
        "claude"      { $TargetDir = "$env:USERPROFILE\.claude\skills\n8n-automation-kit" }
        "cursor"      { $TargetDir = ".\.cursor\rules\n8n-automation-kit" }
        default       { $TargetDir = ".\.agents\skills\n8n-automation-kit" }
    }
}

Write-Host "Target: $TargetDir" -ForegroundColor Green
Write-Host ""

# --- Tier Selection ---
$selectedTiers = @()
if ($Tiers -eq "all") {
    $selectedTiers = @("tier-1-orchestrators", "tier-2-hubs", "tier-3-utilities", "tier-4-domains")
} else {
    foreach ($t in $Tiers.Split(",")) {
        switch ($t.Trim()) {
            "1" { $selectedTiers += "tier-1-orchestrators" }
            "2" { $selectedTiers += "tier-2-hubs" }
            "3" { $selectedTiers += "tier-3-utilities" }
            "4" { $selectedTiers += "tier-4-domains" }
        }
    }
}

# --- Install ---
Write-Host "Installing tiers: $($selectedTiers -join ', ')" -ForegroundColor Cyan

# Create target directory
New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

# Copy root files
Copy-Item "$KitRoot\_moc.md" "$TargetDir\_moc.md" -Force
Copy-Item "$KitRoot\_registry.yaml" "$TargetDir\_registry.yaml" -Force
Copy-Item "$KitRoot\kit.json" "$TargetDir\kit.json" -Force

Write-Host "  [OK] Root files (_moc.md, _registry.yaml, kit.json)" -ForegroundColor Green

# Copy selected tiers
foreach ($tier in $selectedTiers) {
    $sourcePath = "$KitRoot\$tier"
    if (Test-Path $sourcePath) {
        Copy-Item $sourcePath "$TargetDir\$tier" -Recurse -Force
        $skillCount = (Get-ChildItem "$sourcePath" -Directory).Count
        Write-Host "  [OK] $tier ($skillCount skills)" -ForegroundColor Green
    } else {
        Write-Host "  [SKIP] $tier (not found)" -ForegroundColor Yellow
    }
}

# --- Verification ---
Write-Host ""
Write-Host "=== Verification ===" -ForegroundColor Cyan

$totalSkills = (Get-ChildItem "$TargetDir" -Recurse -Filter "SKILL.md").Count
Write-Host "  Total SKILL.md files: $totalSkills" -ForegroundColor Green

if (Test-Path "$TargetDir\_moc.md") {
    Write-Host "  MOC entry point: OK" -ForegroundColor Green
} else {
    Write-Host "  MOC entry point: MISSING" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Installation Complete! ===" -ForegroundColor Green
Write-Host ""
Write-Host "Your AI agent can now use the n8n Automation Kit."
Write-Host "Entry point: $TargetDir\_moc.md"
Write-Host ""
