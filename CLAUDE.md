# Ticket System

This project is a file-based, AI-native ticket workflow system that gets installed into any git repository via a single curl command.

## Dogfooding

We use the ticket system to build the ticket system. The install command:

```bash
curl -sSLf https://raw.githubusercontent.com/kdridi/ticket-system/main/install.sh | bash
```

This installs into the current repo:
- `.tickets/` — system files (config, template, later: commands, hooks, agents)
- `tickets/` — ticket data (backlog, planned, ongoing, completed, rejected)

The full specification lives in `DESIGN.md`.

## Repo layout

- `system/` — source files that get downloaded into `.tickets/` on install
- `install.sh` — the installer script (thin: just fetches files from this repo)
- `DESIGN.md` — full specification and implementation tracking
- `.tickets/` + `tickets/` — installed instance (when present, used to manage our own work)
