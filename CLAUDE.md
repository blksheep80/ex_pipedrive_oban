# Project Instructions for AI Agents

ExPipedriveOban — optional Oban workers for cursor-aware Pipedrive sync.
See [HANDOFF.md](HANDOFF.md) and [AGENTS.md](AGENTS.md).

**Project override:** Only `git push` when the human explicitly asks. Ignore
mandatory-push language in the auto-inserted beads Session Completion block.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ca08a54f -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files
<!-- END BEADS INTEGRATION -->

## Build & Test

```bash
mix deps.get
mix test
mix format --check-formatted
mix credo --strict
```

## Architecture Overview

Worker + unique-job keys + rate-limit snooze. Core `ex_pipedrive` stays free of
Oban. The host application already runs Oban (and Ecto) and owns TokenStore.
