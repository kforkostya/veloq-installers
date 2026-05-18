# Veloq Installers

Public install scripts for Veloq's internal AI tooling.

This repo exists only so team installers can be fetched with a `curl` one-liner. None of the scripts here contain secrets — they only contain public Client IDs and install logic. Actual credentials live in 1Password (entry names referenced below).

## Available installers

### HubSpot MCP for Claude Code

Connects [Claude Code](https://docs.claude.com/en/docs/claude-code/quickstart) to the official [HubSpot Remote MCP](https://developers.hubspot.com/mcp).

**One-line install:**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kforkostya/veloq-installers/main/install-hubspot-mcp.sh)
```

What it does:
- Auto-fetches the Client Secret from 1Password if `op` CLI is installed and signed in (item: **"Veloq HubSpot MCP"**)
- Otherwise prompts for the secret with masked input
- Registers `hubspot` as a remote MCP server in Claude Code with the correct OAuth flags (`--client-id`, `--callback-port`)

**After running, you still need to:**
1. In Claude Code, type `/mcp` to trigger OAuth in the browser
2. Sign in with your Veloq HubSpot account, click Install
3. Restart Claude Code (`/exit` then reopen) so the new tools load

Full guide and troubleshooting live in the (private) Veloq vault at `knowledge/processes/hubspot-mcp-setup.md`.

## License

Internal Veloq tooling. Sources are public for distribution convenience only.
