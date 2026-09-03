#!/usr/bin/env bash
# Idempotent bootstrap for ExPipedrive add-on cloud agents.
# Matches .tool-versions: Elixir 1.17.2, OTP 27.
set -euo pipefail

OTP_VERSION="${EX_PIPEDRIVE_OTP_VERSION:-27.0.1}"
ELIXIR_VERSION="${EX_PIPEDRIVE_ELIXIR_VERSION:-1.17.2}"

ensure_elixir() {
  export PATH="${HOME}/.elixir-install/installs/otp/${OTP_VERSION}/bin:${HOME}/.elixir-install/installs/elixir/${ELIXIR_VERSION}-otp-27/bin:${PATH}"
  if command -v mix >/dev/null 2>&1 && command -v elixir >/dev/null 2>&1; then
    return 0
  fi
  echo "==> Installing Elixir ${ELIXIR_VERSION} / OTP ${OTP_VERSION}"
  curl -fsSL https://elixir-lang.org/install.sh -o /tmp/elixir-install.sh
  sh /tmp/elixir-install.sh "elixir@${ELIXIR_VERSION}" "otp@${OTP_VERSION}"
  export PATH="${HOME}/.elixir-install/installs/otp/${OTP_VERSION}/bin:${HOME}/.elixir-install/installs/elixir/${ELIXIR_VERSION}-otp-27/bin:${PATH}"
}

install_mix_project() {
  local dir="$1"
  echo "==> mix deps.get + compile: $dir"
  cd "$dir"
  mix local.hex --force
  mix local.rebar --force
  mix deps.get
  MIX_ENV=test mix compile --warnings-as-errors
}

ensure_elixir

# Install core if checked out beside this add-on.
SELF_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
CORE_DIR="$(dirname "$SELF_DIR")/ex_pipedrive"
if [ -f "$CORE_DIR/mix.exs" ]; then
  install_mix_project "$CORE_DIR"
fi

install_mix_project "$SELF_DIR"
echo "==> Cloud agent install complete"
