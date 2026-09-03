---
name: hunt-dead-code
description: >-
  Find and remove transitively dead code in ExPipedrive — modules reachable only
  from other dead modules and their own tests. Use when hunting unused code,
  cleaning abandoned subsystems, or auditing what the SDK no longer needs.
---

# Hunt Dead Code (ExPipedrive)

Dead means **unreachable from declared roots**, where tests are not roots.

**Static analysis proposes; the compiler and test suite dispose.** Never delete
on the analyzer's say-alone.

## 1. Run the analyzer

```bash
elixir .cursor/skills/hunt-dead-code/scripts/dead_code.exs
```

`--json` for machine-readable output, `--root DIR` to analyze elsewhere.

| Section | Confidence | Action |
|---|---|---|
| Dead clusters | High | One cluster per bead/PR |
| Tests to delete outright | High | Delete with cluster |
| Tests needing surgical edits | High | Remove dead `describe` blocks only |
| Unused public API | Advisory | Human judgment — Hex package |
| Unreferenced / test-only functions | Advisory | Read each one |

## 2. Triage

See [reference.md](reference.md). Before deleting:

```bash
rg 'ModuleName|:module_name' --type elixir --type markdown
git log --oneline --follow -- path/to/module.ex
```

## 3. Ticket and branch

```bash
bd create "Remove dead <cluster name>" --type task --priority 3
bd update <id> --claim
git checkout -b issue/<id>-remove-<slug>
```

One cluster per ticket.

## 4. Delete the whole unit

Delete cluster modules together with listed test files and dead `describe` blocks.
Remove unused `alias` lines and stale docs references.

## 5. Verification gate

```bash
mix compile --force --warnings-as-errors
mix format --check-formatted
mix credo --strict
mix dialyzer
mix test
```

## 6. Land or ratchet

**Green** — commit, `bd close <id>`.

**Red** — revert and add to `roots.exs` with the reason it is reachable:

```elixir
roots: [
  {"lib/ex_pipedrive/some/module.ex", "Selected at runtime via Client middleware list"}
]
```

## Files

- `scripts/dead_code.exs` — analyzer (layout-agnostic; do not fork per repo)
- `roots.exs` — ExPipedrive-specific roots and public API globs
- `reference.md` — false-positive taxonomy
