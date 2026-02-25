#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
hook_path="$repo_root/.git/hooks/pre-commit"

cat > "$hook_path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if command -v mise >/dev/null 2>&1; then
	exec mise x pre-commit -- pre-commit run --config .pre-commit-config.yaml --hook-stage pre-commit "$@"
fi

if [ -x "$HOME/.local/bin/mise" ]; then
	exec "$HOME/.local/bin/mise" x pre-commit -- pre-commit run --config .pre-commit-config.yaml --hook-stage pre-commit "$@"
fi

echo "mise not found; cannot run pre-commit hook" >&2
exit 1
EOF

chmod +x "$hook_path"
echo "Installed pre-commit hook at $hook_path"
