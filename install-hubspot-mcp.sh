#!/usr/bin/env bash
# Veloq HubSpot MCP installer for Claude Code
#
# Usage (one-liner):
#   bash <(curl -fsSL https://raw.githubusercontent.com/kforkostya/veloq-installers/main/install-hubspot-mcp.sh)
#
# What it does:
#   Registers HubSpot as a remote MCP server in Claude Code, wrapped with
#   `mcp-remote` so OAuth tokens auto-refresh across sessions. Without this
#   wrapper, Claude Code's broken refresh logic forces a manual /mcp
#   re-authentication on every session start (see GitHub issues #25245,
#   #28262, #40582 on anthropics/claude-code).
#
# Prereqs:
#   - Claude Code installed (https://docs.claude.com/en/docs/claude-code/quickstart)
#   - Node.js installed (mcp-remote runs as an npx subprocess)
#   - HubSpot user account on the Veloq portal
#   - Client Secret from 1Password (item "Veloq HubSpot MCP")
#     - If 1Password CLI (`op`) is installed and signed in, the secret is fetched automatically
#     - Otherwise the script will prompt for it (masked input)

set -euo pipefail

CLIENT_ID="16f3d5e7-c465-4244-8ea8-598e73b3e838"
SERVER_URL="https://mcp.hubspot.com/"
MCP_REMOTE_VERSION="0.1.38"
CALLBACK_PORT="8765"
OP_ITEM="Veloq HubSpot MCP"

if ! command -v claude &>/dev/null; then
  echo "ERROR: Claude Code CLI not found in PATH."
  echo "Install it from https://docs.claude.com/en/docs/claude-code/quickstart first, then rerun."
  exit 1
fi

if ! command -v node &>/dev/null; then
  echo "ERROR: Node.js not found in PATH."
  echo "mcp-remote runs via npx so Node is required. Install Node, then rerun."
  exit 1
fi

cat <<'BANNER'
============================================
 Veloq HubSpot MCP installer for Claude Code
 (wrapped with mcp-remote for auth persistence)
============================================
BANNER
echo ""

CLIENT_SECRET=""

# Try 1Password CLI auto-fetch first
if command -v op &>/dev/null; then
  echo "1Password CLI detected; trying to fetch secret from '$OP_ITEM'..."
  if CLIENT_SECRET=$(op item get "$OP_ITEM" --fields=password --reveal 2>/dev/null); then
    if [ -n "$CLIENT_SECRET" ]; then
      echo "Found secret in 1Password. No paste needed."
    fi
  fi
  if [ -z "$CLIENT_SECRET" ]; then
    echo "Couldn't auto-fetch from 1Password (item not found, wrong field, or not signed in)."
    echo "Run 'op signin' if needed, or just paste the secret manually below."
  fi
fi

# Fall back to manual prompt
if [ -z "$CLIENT_SECRET" ]; then
  echo ""
  echo "Paste the Client Secret from 1Password item '$OP_ITEM',"
  echo "then press Enter. Input is hidden, won't appear on screen."
  read -rs CLIENT_SECRET
  echo ""
fi

if [ -z "$CLIENT_SECRET" ]; then
  echo "ERROR: empty secret. Aborting."
  exit 1
fi

# Bake real values into the JSON at install time. mcp-remote does NOT
# expand ${...} placeholders inside --static-oauth-client-info, so we
# interpolate here. The JSON lands in ~/.claude.json args; that file
# is user-readable only.
CLIENT_INFO_JSON=$(printf '{ "client_id": "%s", "client_secret": "%s" }' "$CLIENT_ID" "$CLIENT_SECRET")

# Clean slate (silently drop any prior config and stale auth cache)
claude mcp remove hubspot 2>/dev/null || true
rm -rf ~/.mcp-auth

# User scope so it's available from every directory, not just one project.
# Fixed callback port so the redirect URL stays stable.
claude mcp add hubspot --scope user \
  -- npx -y "mcp-remote@${MCP_REMOTE_VERSION}" \
     "$SERVER_URL" \
     "$CALLBACK_PORT" \
  --static-oauth-client-info "$CLIENT_INFO_JSON"

unset CLIENT_SECRET CLIENT_INFO_JSON

cat <<'NEXT'

MCP server registered. Two more steps:

  1. In Claude Code, type:    /mcp
     Browser opens -> sign in with your Veloq HubSpot account -> click Install.

  2. Quit Claude Code (/exit) and reopen it so the new tools load.

Verify with this prompt in a fresh session:
   Use the hubspot MCP and call get_user_details to confirm I'm authenticated.

After OAuth completes, mcp-remote handles token refresh in ~/.mcp-auth/
so you should never see the re-auth prompt again across sessions.

If OAuth fails with "redirect URL doesn't match", ping Konstantin:
the Veloq Internal MCP app in HubSpot must have
"http://localhost:8765/oauth/callback" in its Redirect URLs list.
NEXT
