# agents-config
Repo to track configuration files (*.md, skills, MCP, etc.) and personal preferences for AI coding agents.

## Contents

```
.claude/
  CLAUDE.md                              # general guidelines
  rules/coding/CODE-STYLE.md             # code style rules
  rules/communication/COMMUNICATION-STYLE.md  # chat/response rules
```

## Install

Copies `.claude/CLAUDE.md` and everything under `.claude/rules/` into your home
`.claude` folder (`~/.claude` / `%USERPROFILE%\.claude`), making it apply to every project.

**This overwrites `~/.claude/CLAUDE.md` and any same-named files under `~/.claude/rules/`.**
Back those up first if you have your own.

Run the script from the root of this repo.

### Windows (PowerShell)

```powershell
$dest = "$env:USERPROFILE\.claude"
New-Item -ItemType Directory -Force -Path "$dest\rules" | Out-Null
Copy-Item -Path ".claude\CLAUDE.md" -Destination $dest -Force
Copy-Item -Path ".claude\rules\*" -Destination "$dest\rules" -Recurse -Force
```

### macOS / Linux (bash or zsh)

```bash
dest="$HOME/.claude"
mkdir -p "$dest/rules"
cp .claude/CLAUDE.md "$dest/CLAUDE.md"
cp -R .claude/rules/. "$dest/rules/"
```

### Verify

```powershell
# Windows
Get-ChildItem -Recurse "$env:USERPROFILE\.claude\CLAUDE.md", "$env:USERPROFILE\.claude\rules"
```

```bash
# macOS / Linux
find "$HOME/.claude/CLAUDE.md" "$HOME/.claude/rules" -type f
```