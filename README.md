# Veloq Installers

Public install scripts for Veloq's internal AI tooling.

This repo exists only so team installers can be fetched with a `curl` one-liner. None of the scripts here contain secrets — they only contain public Client IDs and install logic. Actual credentials live in 1Password (entry names referenced below).

## Available installers

### HubSpot MCP for Claude Code

Connects [Claude Code](https://docs.claude.com/en/docs/claude-code/quickstart) to the official [HubSpot Remote MCP](https://developers.hubspot.com/mcp), wrapped with [`mcp-remote`](https://github.com/geelen/mcp-remote) so OAuth tokens auto-refresh across sessions.

**Why the wrapper?** Claude Code's built-in HTTP MCP OAuth implementation has a known bug ([#25245](https://github.com/anthropics/claude-code/issues/25245), [#28262](https://github.com/anthropics/claude-code/issues/28262), [#40582](https://github.com/anthropics/claude-code/issues/40582)): refresh tokens are stored but never used, so users get prompted to re-authenticate on every session start. `mcp-remote` is the de facto community workaround: it proxies the remote MCP locally and handles token refresh in `~/.mcp-auth/`.

**One-line install:**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kforkostya/veloq-installers/main/install-hubspot-mcp.sh)
```

What it does:
- Auto-fetches the Client Secret from 1Password if `op` CLI is installed and signed in (item: **"Veloq HubSpot MCP"**)
- Otherwise prompts for the secret with masked input
- Registers `hubspot` as a user-scope MCP server in Claude Code
- Wraps with `mcp-remote@0.1.38` (pinned version) on a fixed callback port (8765)

**After running, you still need to:**
1. In Claude Code, type `/mcp` to trigger OAuth in the browser
2. Sign in with your Veloq HubSpot account, click Install
3. Restart Claude Code (`/exit` then reopen) so the new tools load

After OAuth completes, you should never see the re-auth prompt again.

**Prereqs:**
- Claude Code installed
- Node.js installed (for `npx` to run `mcp-remote`)
- HubSpot user account on the Veloq portal
- Client Secret from 1Password (item "Veloq HubSpot MCP")

Full team guide and troubleshooting live in the (private) Veloq vault at `knowledge/processes/hubspot-mcp-setup.md`.

## License

Internal Veloq tooling. Sources are public for distribution convenience only.
