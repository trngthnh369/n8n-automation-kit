<#
.SYNOPSIS
    Sets up n8n-custom-mcp server for the n8n Automation Kit.
    This enables the full Self-Healing Loop (execute → check → fix → retry).
.PARAMETER N8nUrl
    Your n8n instance URL (e.g., https://your-n8n.example.com)
.PARAMETER N8nApiKey
    Your n8n API key (from n8n Settings → API)
.PARAMETER Port
    MCP server port (default: 3000)
#>
param(
    [string]$N8nUrl = "",
    [string]$N8nApiKey = "",
    [int]$Port = 3000
)

Write-Host ""
Write-Host "⚡ n8n-custom-mcp Setup" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
$missingDeps = @()
if (!(Get-Command node -ErrorAction SilentlyContinue)) { $missingDeps += "Node.js (https://nodejs.org)" }
if (!(Get-Command git -ErrorAction SilentlyContinue)) { $missingDeps += "Git (https://git-scm.com)" }

if ($missingDeps.Count -gt 0) {
    Write-Host "❌ Missing dependencies:" -ForegroundColor Red
    $missingDeps | ForEach-Object { Write-Host "   - $_" -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "Install them first, then re-run this script." -ForegroundColor Yellow
    exit 1
}

# Get n8n URL and API key
if (-not $N8nUrl) {
    $N8nUrl = Read-Host "🌐 Enter your n8n URL (e.g., https://your-n8n.example.com)"
}
if (-not $N8nApiKey) {
    $N8nApiKey = Read-Host "🔑 Enter your n8n API Key (from n8n Settings → API)"
}

$N8nUrl = $N8nUrl.TrimEnd('/')

# Clone and build MCP server
$McpDir = Join-Path $PSScriptRoot ".." "n8n-custom-mcp"

if (Test-Path $McpDir) {
    Write-Host "📁 MCP server already exists at $McpDir" -ForegroundColor Yellow
    $update = Read-Host "   Update? (y/n)"
    if ($update -eq 'y') {
        Set-Location $McpDir
        git pull
    }
} else {
    Write-Host "📥 Cloning n8n-custom-mcp..." -ForegroundColor Cyan
    git clone https://github.com/czlonkowski/n8n-mcp.git $McpDir
}

Set-Location $McpDir

Write-Host "📦 Installing dependencies..." -ForegroundColor Cyan
npm install

Write-Host "🔨 Building..." -ForegroundColor Cyan
npm run build

# Create .env
$envContent = @"
N8N_BASE_URL=$N8nUrl
N8N_API_KEY=$N8nApiKey
PORT=$Port
"@
Set-Content -Path ".env" -Value $envContent

Write-Host ""
Write-Host "✅ n8n-custom-mcp installed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Start MCP server:" -ForegroundColor White
Write-Host "     cd $McpDir && npm start" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Add to your AI agent's MCP config:" -ForegroundColor White
Write-Host ""

# Generate MCP config snippet
$configSnippet = @"
{
  "mcpServers": {
    "n8n": {
      "command": "node",
      "args": ["$($McpDir -replace '\\', '/')/dist/index.js"],
      "env": {
        "N8N_BASE_URL": "$N8nUrl",
        "N8N_API_KEY": "$N8nApiKey"
      }
    }
  }
}
"@

Write-Host $configSnippet -ForegroundColor Cyan
Write-Host ""
Write-Host "  Config file locations:" -ForegroundColor White
Write-Host "    Antigravity: .gemini/settings.json" -ForegroundColor Gray
Write-Host "    Claude Code: .claude/mcp.json" -ForegroundColor Gray
Write-Host "    Cursor:      .cursor/mcp.json" -ForegroundColor Gray
Write-Host ""
Write-Host "  3. Restart your AI agent to load MCP tools" -ForegroundColor White
Write-Host ""
Write-Host "🔗 Verify: Ask your agent 'list_workflows' — if it works, you're ready!" -ForegroundColor Green
