# ExPipedriveOban handoff

Status as of 2026-09-03. Use this when starting a new agent session in this repo.

## Current state

- Hex **0.1.1** on [`ex_pipedrive_oban`](https://hex.pm/packages/ex_pipedrive_oban).
- GitHub: [`blksheep80/ex_pipedrive_oban`](https://github.com/blksheep80/ex_pipedrive_oban) (own remote; split from core via [ex_pipedrive#130](https://github.com/blksheep80/ex_pipedrive/issues/130)).
- Owns `ExPipedriveOban.SyncWorker`, unique-job keys, and rate-limit snooze.
- Host app implements `ExPipedriveOban.Source` and already runs Oban + Ecto.
- Supported `resource` values: `deals`, `persons`, `organizations`.

## Locked decisions

| Item | Decision |
|---|---|
| Hex / GitHub / OTP app | `ex_pipedrive_oban` |
| Scope | Worker + unique keys + snooze. No Oban instance, no repo, no TokenStore |
| Core coupling | `ex_pipedrive ~> 0.2` on Hex/CI; path dep when `../ex_pipedrive` exists |
| Publish | `HEX_PUBLISH=1 mix hex.publish` when a local core checkout is present |

## Tracking (this repo only)

| Layer | Use for |
|---|---|
| `HANDOFF.md` | Where we are / locked decisions |
| GitHub issues on **this** repo | Product backlog, acceptance criteria |
| beads (`expdo-`) | Work in flight; close with reason |

Core SDK work goes to [`ex_pipedrive`](https://github.com/blksheep80/ex_pipedrive)
(`expd-`). Cross-package changes: file the driving issue on the repo that owns
the change, and link a follow-up on the other.

Fresh clone: `bd bootstrap`.

## Remotes

- `origin` → `blksheep80/ex_pipedrive_oban`

This clone must default to **this** repo (multi-root workspace makes `gh`
easy to point at the wrong package):

```bash
gh repo set-default origin
gh repo set-default --view   # expect blksheep80/ex_pipedrive_oban
```

## Local tooling

- **Beads** (`bd`, prefix `expdo-`): execution-of-record. Cursor rule at `.cursor/rules/beads.mdc`.
- **GitHub issues**: product backlog on this repo.
- **Cursor skills**: `.cursor/skills/ex-pipedrive-oban-session`, `.cursor/skills/ex-pipedrive-oban-pr`.
- **asdf / mise**: `.tool-versions` for Elixir/OTP.

## How to resume

1. Read this file (and the session skill if present).
2. `bd ready` for in-flight execution items.
3. Prefer GitHub issues on **this** repo for the backlog; create/claim a bead when starting concrete work.
4. Prefer this file + GitHub issues + beads over chat transcript memory.
