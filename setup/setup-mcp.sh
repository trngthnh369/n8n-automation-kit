#!/bin/bash
set -e

echo ""
echo "⚡ n8n-custom-mcp Setup"
echo "========================"
echo ""

# Check prerequisites
MISSING=""
command -v node >/dev/null 2>&1 || MISSING="$MISSING Node.js(https://nodejs.org)"
command -v git >/dev/null 2>&1 || MISSING="$MISSING Git(https://git-scm.com)"

if [ -n "$MISSING" ]; then
  echo "❌ Missing dependencies:$MISSING"
  echo "Install them first, then re-run this script."
  exit 1
fi

# Get config
N8N_URL="${1:-}"
N8N_API_KEY="${2:-}"
PORT="${3:-3000}"

if [ -z "$N8N_URL" ]; then
  read -p "🌐 Enter your n8n URL (e.g., https://your-n8n.example.com): " N8N_URL
fi
if [ -z "$N8N_API_KEY" ]; then
  read -p "🔑 Enter your n8n API Key (from n8n Settings → API): " N8N_API_KEY
fi

N8N_URL="${N8N_URL%/}"  # Remove trailing slash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MCP_DIR="$SCRIPT_DIR/../n8n-custom-mcp"

# Clone or update
if [ -d "$MCP_DIR" ]; then
  echo "📁 MCP server already exists at $MCP_DIR"
  read -p "   Update? (y/n): " UPDATE
  if [ "$UPDATE" = "y" ]; then
    cd "$MCP_DIR" && git pull
  fi
else
  echo "📥 Cloning n8n-custom-mcp..."
  git clone https://github.com/czlonkowski/n8n-mcp.git "$MCP_DIR"
fi

cd "$MCP_DIR"

echo "📦 Installing dependencies..."
npm install

echo "🔨 Building..."
npm run build

# Create .env
cat > .env << EOF
N8N_BASE_URL=$N8N_URL
N8N_API_KEY=$N8N_API_KEY
PORT=$PORT
EOF

echo ""
echo "✅ n8n-custom-mcp installed!"
echo ""
echo "📋 Next Steps:"
echo "  1. Start MCP server:"
echo "     cd $MCP_DIR && npm start"
echo ""
echo "  2. Add to your AI agent's MCP config:"
echo ""
cat << EOF
{
  "mcpServers": {
    "n8n": {
      "command": "node",
      "args": ["$MCP_DIR/dist/index.js"],
      "env": {
        "N8N_BASE_URL": "$N8N_URL",
        "N8N_API_KEY": "$N8N_API_KEY"
      }
    }
  }
}
EOF
echo ""
echo "  Config file locations:"
echo "    Antigravity: .gemini/settings.json"
echo "    Claude Code: .claude/mcp.json"
echo "    Cursor:      .cursor/mcp.json"
echo ""
echo "  3. Restart your AI agent to load MCP tools"
echo ""
echo "🔗 Verify: Ask your agent 'list_workflows' — if it works, you're ready!"
