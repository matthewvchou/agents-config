#!/usr/bin/env bash
# Script for Linux & MacOS
# Copies CLAUDE.md, rules/, and skills/ from this repo's .claude into ~/.claude.
# Overwrites ~/.claude/CLAUDE.md and same-named files under ~/.claude/rules/ and ~/.claude/skills/.
set -euo pipefail

# Resolve the source from the script location so it works from any directory.
src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="$HOME/.claude"

mkdir -p "$dest/rules" "$dest/skills"
cp "$src/CLAUDE.md" "$dest/CLAUDE.md"
cp -R "$src/rules/." "$dest/rules/"
cp -R "$src/skills/." "$dest/skills/"

find "$dest/CLAUDE.md" "$dest/rules" "$dest/skills" -type f
