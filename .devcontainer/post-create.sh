#!/bin/sh
set -eu

# The state volume is mounted as root; hand it to the container user.
sudo chown vscode:vscode /var/dev-state

# Seed Claude's user settings with the host's statusLine. Merge, never replace:
# agents.yaml later adds enabledPlugins to this same file, and a rebuild must
# not drop them.
config="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
seed="/workspaces/buzz-containers/.devcontainer/claude-settings.json"
mkdir -p "$config"
tmp="$config/settings.json.tmp"
if [ -f "$config/settings.json" ]; then
  jq -s '.[0] * .[1]' "$config/settings.json" "$seed" > "$tmp"
else
  jq '.' "$seed" > "$tmp"
fi
mv "$tmp" "$config/settings.json"
