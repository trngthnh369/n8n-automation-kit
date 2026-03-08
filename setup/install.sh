#!/bin/bash
# n8n Automation Kit Installer for macOS/Linux
# Usage: ./install.sh [--agent antigravity|claude|gemini|cursor] [--tiers all|1,2,3,4] [--target /path]

set -e

KIT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KIT_ROOT="$(dirname "$SCRIPT_DIR")"

AGENT="auto"
TARGET_DIR=""
TIERS="all"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --agent) AGENT="$2"; shift 2 ;;
        --target) TARGET_DIR="$2"; shift 2 ;;
        --tiers) TIERS="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo ""
echo "=== n8n Automation Kit Installer v$KIT_VERSION ==="
echo ""

# Auto-detect agent
if [ "$AGENT" = "auto" ]; then
    if [ -d ".agents" ] || [ -d ".agent" ]; then
        AGENT="antigravity"
    elif [ -d "$HOME/.claude" ]; then
        AGENT="claude"
    elif [ -d ".cursor" ]; then
        AGENT="cursor"
    else
        AGENT="antigravity"
    fi
    echo "Auto-detected agent: $AGENT"
fi

# Set target directory
if [ -z "$TARGET_DIR" ]; then
    case $AGENT in
        antigravity|gemini) TARGET_DIR=".agents/skills/n8n-automation-kit" ;;
        claude) TARGET_DIR="$HOME/.claude/skills/n8n-automation-kit" ;;
        cursor) TARGET_DIR=".cursor/rules/n8n-automation-kit" ;;
        *) TARGET_DIR=".agents/skills/n8n-automation-kit" ;;
    esac
fi

echo "Target: $TARGET_DIR"
echo ""

# Create target
mkdir -p "$TARGET_DIR"

# Copy root files
cp "$KIT_ROOT/_moc.md" "$TARGET_DIR/_moc.md"
cp "$KIT_ROOT/_registry.yaml" "$TARGET_DIR/_registry.yaml"
cp "$KIT_ROOT/kit.json" "$TARGET_DIR/kit.json"
echo "  [OK] Root files"

# Copy tiers
TIER_DIRS=()
if [ "$TIERS" = "all" ]; then
    TIER_DIRS=("tier-1-orchestrators" "tier-2-hubs" "tier-3-utilities" "tier-4-domains")
else
    IFS=',' read -ra TIER_NUMS <<< "$TIERS"
    for t in "${TIER_NUMS[@]}"; do
        case $t in
            1) TIER_DIRS+=("tier-1-orchestrators") ;;
            2) TIER_DIRS+=("tier-2-hubs") ;;
            3) TIER_DIRS+=("tier-3-utilities") ;;
            4) TIER_DIRS+=("tier-4-domains") ;;
        esac
    done
fi

for tier in "${TIER_DIRS[@]}"; do
    if [ -d "$KIT_ROOT/$tier" ]; then
        cp -r "$KIT_ROOT/$tier" "$TARGET_DIR/$tier"
        count=$(find "$KIT_ROOT/$tier" -maxdepth 1 -type d | wc -l)
        echo "  [OK] $tier ($((count-1)) skills)"
    else
        echo "  [SKIP] $tier (not found)"
    fi
done

# Verification
echo ""
echo "=== Verification ==="
total=$(find "$TARGET_DIR" -name "SKILL.md" | wc -l)
echo "  Total SKILL.md files: $total"
echo ""
echo "=== Installation Complete! ==="
echo "Entry point: $TARGET_DIR/_moc.md"
echo ""
