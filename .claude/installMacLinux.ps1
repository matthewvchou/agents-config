#!/usr/bin/env bash
# Script for Linux & MacOS
# Copies CLAUDE.md and rules/ from this repo's .claude into ~/.claude.
# Overwrites ~/.claude/CLAUDE.md and same-named files under ~/.claude/rules/.
set -euo pipefail

# Resolve the source from the script location so it works from any directory.
src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="$HOME/.claude"

mkdir -p "$dest/rules"
cp "$src/CLAUDE.md" "$dest/CLAUDE.md"
cp -R "$src/rules/." "$dest/rules/"

find "$dest/CLAUDE.md" "$dest/rules" -type f
