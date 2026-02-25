#!/usr/bin/env bash
set -euo pipefail

repo_root="$(pwd)"

need_apt=0
packages=()
if ! command -v git-lfs >/dev/null 2>&1; then
  need_apt=1
  packages+=(git-lfs)
fi
if ! command -v python3 >/dev/null 2>&1; then
  need_apt=1
  packages+=(python3 python3-venv)
fi

if [ "$need_apt" -eq 1 ]; then
  sudo apt-get update
  sudo apt-get install -y "${packages[@]}"
fi

git lfs install

if [ ! -x "$HOME/.local/bin/mise" ]; then
  curl -fsSL https://mise.jdx.dev/install.sh | sh
fi

if ! grep -Fq 'eval "$(~/.local/bin/mise activate bash)"' "$HOME/.bashrc"; then
  echo 'eval "$(~/.local/bin/mise activate bash)"' >> "$HOME/.bashrc"
fi

"$HOME/.local/bin/mise" trust "$repo_root/mise.toml"

export MISE_HTTP_TIMEOUT="${MISE_HTTP_TIMEOUT:-120}"

attempt=1
max_attempts=3
until "$HOME/.local/bin/mise" install; do
  if [ "$attempt" -ge "$max_attempts" ]; then
    echo "mise install failed after ${max_attempts} attempts" >&2
    exit 1
  fi
  sleep_seconds=$((attempt * 10))
  echo "mise install failed (attempt ${attempt}/${max_attempts}); retrying in ${sleep_seconds}s..." >&2
  sleep "$sleep_seconds"
  attempt=$((attempt + 1))
done

mkdir -p "$repo_root/.terraform.d/plugin-cache"
