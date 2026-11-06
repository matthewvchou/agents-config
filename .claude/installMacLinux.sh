#!/usr/bin/env bash
# Script for Linux & MacOS
# Copies CLAUDE.md, rules/, and skills/ from this repo's .claude into ~/.claude.
# Overwrites ~/.claude/CLAUDE.md and same-named files under ~/.claude/rules/ and ~/.claude/skills/.
# Creates ~/.claude/settings.json from settings.template.json, or merges the template into it (needs jq):
# template scalars and enabledPlugins overwrite, permissions.deny is a union, other keys are kept.
set -euo pipefail

# Resolve the source from the script location so it works from any directory.
src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="$HOME/.claude"

mkdir -p "$dest/rules" "$dest/skills"
cp "$src/CLAUDE.md" "$dest/CLAUDE.md"
cp -R "$src/rules/." "$dest/rules/"
cp -R "$src/skills/." "$dest/skills/"

template="$src/settings.template.json"
settings="$dest/settings.json"

if [ ! -f "$settings" ]; then
  cp "$template" "$settings"
elif ! command -v jq >/dev/null 2>&1; then
  echo "jq not found: skipped settings.json merge, file left unchanged." >&2
else
  # Union on permissions.deny so deny rules already on this machine are kept.
  # Other template keys overwrite; keys absent from the template are kept.
  tmp="$(mktemp)"
  if jq --slurpfile tpl "$template" '
      ($tpl[0] | del(.permissions)) as $overrides
      | (.permissions.deny // []) as $existing
      | . * $overrides
      | .enabledPlugins = $tpl[0].enabledPlugins
      | .permissions.deny = ($existing + $tpl[0].permissions.deny | unique)
    ' "$settings" > "$tmp"; then
    mv "$tmp" "$settings"
  else
    rm -f "$tmp"
    echo "Could not merge settings.json: file left unchanged." >&2
  fi
fi

find "$dest/CLAUDE.md" "$dest/rules" "$dest/skills" -type f
[ -f "$settings" ] && echo "$settings"
