---
name: improve-test-coverage
description: >-
  Systematically improve ExPipedrive test coverage by targeting high-ROI modules.
  Use when raising coverage toward the 75% CI floor, after coverage regressions,
  or when the user asks for coverage quick-wins.
---

# Improve Test Coverage (ExPipedrive)

Increase coverage with meaningful behavior tests — not line-farming.

## Setup

Scripts live in `.cursor/skills/improve-test-coverage/scripts/`:

- `coverage_progress.exs` — overall stats and tier distribution
- `find_quick_wins.exs` — modules at 85–99% with few uncovered lines
- `find_uncovered_lines.exs` — uncovered lines for one module
- `compare_coverage.exs` — diff two runs for flaky/property-test gaps

## Workflow

### 1. Analyze

```bash
mix coveralls.json
elixir .cursor/skills/improve-test-coverage/scripts/coverage_progress.exs
```

### 2. Pick targets

```bash
elixir .cursor/skills/improve-test-coverage/scripts/find_quick_wins.exs
```

Prioritize: highest % first, fewest uncovered lines, simpler modules before servers.

### 3. Inspect gaps

```bash
elixir .cursor/skills/improve-test-coverage/scripts/find_uncovered_lines.exs lib/ex_pipedrive/client.ex
```

### 4. Ticket and branch

```bash
bd create "Raise coverage: <module>" --type task --priority 3
bd update <id> --claim
git checkout -b issue/<id>-coverage-<slug>
```

### 5. Write tests

- Name tests for **behavior**, not line numbers
- Use `FakePipedriveServer` / existing fixtures in `test/support/`
- Prefer resource-module tests under `test/<resource>/`

### 6. Verify

```bash
mix test path/to/test_file.exs
mix coveralls.json
elixir .cursor/skills/improve-test-coverage/scripts/coverage_progress.exs
mix format --check-formatted
mix credo --strict
```

Full gate before PR (match CI):

```bash
mix test
mix dialyzer
```

### 7. Close

```bash
bd close <id> --reason "Coverage: <module> to 100% in <sha>"
```

## Anti-patterns

- Do not write trivial tests just to hit lines
- Do not skip understanding the code under test
- Do not weaken the 75% Coveralls floor in CI

## Prioritization

| Tier | Action |
|---|---|
| 95–99%, 1–2 lines | Immediate |
| 90–95%, 1–5 lines | High |
| 85–90%, 1–10 lines | Medium |
| <85% or >10 lines | Defer unless blocking a release |
