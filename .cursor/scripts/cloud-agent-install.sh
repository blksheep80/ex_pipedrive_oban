#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
mix local.hex --force
mix local.rebar --force
mix deps.get
MIX_ENV=test mix compile --warnings-as-errors
if [ -d "../ex_pipedrive/mix.exs" ]; then
  (cd ../ex_pipedrive && mix deps.get && MIX_ENV=test mix compile --warnings-as-errors)
fi
echo "==> install complete"
