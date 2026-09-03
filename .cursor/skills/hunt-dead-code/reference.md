# Dead-code detection: what defeats static analysis

Reference for triage in [SKILL.md](SKILL.md). ExPipedrive-specific notes.

## Why not `mix xref` alone

`mix xref` cannot see through `quote` / `__using__` macros. The analyzer builds
its graph from source AST instead (including `quote` blocks), which
over-approximates liveness — the safe direction for a published library.

## False-positive classes in ExPipedrive

### Tesla middleware

`ExPipedrive.Middleware.Retry` and `Telemetry` are referenced via Client opts,
not static aliases. Declared in `roots.exs`.

### FakePipedriveServer handlers

Handlers under `test/support/fake_*_api_handler.ex` are wired at test runtime.
The fake server itself is a declared root.

### Resource behaviour / Raw escape hatch

`ExPipedrive.Resource` and `ExPipedrive.Raw` are public API and roots via
`public_api` globs. Do not delete because xref shows low in-degree.

### Webhook handler callback

Host apps implement `ExPipedrive.Webhook.Handler` — no static edge from core.

### OAuth TokenStore implementations

Pluggable at runtime via config/behaviour; custom impls may look unused internally.

## Verification gate (ExPipedrive)

```bash
mix compile --force --warnings-as-errors
mix format --check-formatted
mix credo --strict
mix dialyzer
mix test
```

No distributed/minio suite — unlike Bedrock, unit + fake-server tests are the gate.

## Hex public API

`public_api` entries are **advisory** when uncalled internally. Downstream Hex
consumers may use any exported module. Removing one needs its own bead, CHANGELOG
entry, and semver judgment.

## Things that are not evidence of life

- Incoming references from tests only (tests are not roots)
- References from other dead modules (deadness is transitive)
- `@moduledoc` describing planned work
- Mentions in README without a call edge
