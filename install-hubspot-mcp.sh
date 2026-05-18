#!/usr/bin/env bash
# Veloq HubSpot MCP installer for Claude Code
#
# Usage (one-liner):
#   bash <(curl -fsSL https://raw.githubusercontent.com/kforkostya/veloq-installers/main/install-hubspot-mcp.sh)
#
# Prereqs:
#   - Claude Code installed (https://docs.claude.com/en/docs/claude-code/quickstart)
#   - HubSpot user account on the Veloq portal
#   - Client Secret from 1Password (item "Veloq HubSpot MCP")
#     - If 1Password CLI (`op`) is installed and signed in, the secret is fetched automatically
#     - Otherwise the script will prompt for it (masked input)

set -euo pipefail

CLIENT_ID="16f3d5e7-c465-4244-8ea8-598e73b3e838"
SERVER_URL="https://mcp.hubspot.com/"
CALLBACK_PORT=3334
OP_ITEM="Veloq HubSpot MCP"

if ! command -v claude &>/dev/null; then
  echo "ERROR: Claude Code CLI not found in PATH."
  echo "Install it from https://docs.claude.com/en/docs/claude-code/quickstart first, then rerun."
  exit 1
fi

cat <<'BANNER'

  ██╗   ██╗███████╗██╗      ██████╗  ██████╗
  ██║   ██║██╔════╝██║     ██╔═══██╗██╔═══██╗
  ██║   ██║█████╗  ██║     ██║   ██║██║   ██║
  ╚██╗ ██╔╝██╔══╝  ██║     ██║   ██║██║▄▄ ██║
   ╚████╔╝ ███████╗███████╗╚██████╔╝╚██████╔╝
    ╚═══╝  ╚══════╝╚══════╝ ╚═════╝  ╚══▀▀═╝

  HubSpot MCP installer for Claude Code

BANNER
echo ""

MCP_CLIENT_SECRET=""

# Try 1Password CLI auto-fetch first
if command -v op &>/dev/null; then
  echo "1Password CLI detected; trying to fetch secret from '$OP_ITEM'..."
  if MCP_CLIENT_SECRET=$(op item get "$OP_ITEM" --fields=password --reveal 2>/dev/null); then
    if [ -n "$MCP_CLIENT_SECRET" ]; then
      echo "Found secret in 1Password. No paste needed."
    fi
  fi
  if [ -z "$MCP_CLIENT_SECRET" ]; then
    echo "Couldn't auto-fetch from 1Password (item not found, wrong field, or not signed in)."
    echo "Run 'op signin' if needed, or just paste the secret manually below."
  fi
fi

# Fall back to manual prompt
if [ -z "$MCP_CLIENT_SECRET" ]; then
  echo ""
  echo "Paste the Client Secret from 1Password item '$OP_ITEM',"
  echo "then press Enter. Input is hidden, won't appear on screen."
  read -rs MCP_CLIENT_SECRET
  echo ""
fi

if [ -z "$MCP_CLIENT_SECRET" ]; then
  echo "ERROR: empty secret. Aborting."
  exit 1
fi

export MCP_CLIENT_SECRET

# Clean slate (silently drop any prior broken config)
claude mcp remove hubspot 2>/dev/null || true

claude mcp add --transport http \
  --client-id "$CLIENT_ID" \
  --client-secret \
  --callback-port "$CALLBACK_PORT" \
  hubspot \
  "$SERVER_URL"

unset MCP_CLIENT_SECRET

cat <<'NEXT'

MCP server registered. Two more steps:

  1. In Claude Code, type:    /mcp
     Browser opens -> sign in with your Veloq HubSpot account -> click Install.

  2. Quit Claude Code (/exit) and reopen it so the new tools load.

Verify with this prompt in a fresh session:
   Use the hubspot MCP and call get_user_details to confirm I'm authenticated.

If anything fails, see ~/veloq-vault/knowledge/processes/hubspot-mcp-setup.md
or ping Konstantin.
NEXT
