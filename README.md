# agents-config
Repo to track configuration files (*.md, skills, MCP, etc.) and personal preferences for AI coding agents.

## Contents

```
.claude/
  CLAUDE.md                              # general guidelines
  installMacLinux.ps1                    # installer for macOS / Linux (bash script)
  installWindows.ps1                     # installer for Windows
  rules/coding/CODE-STYLE.md             # code style rules
  rules/communication/COMMUNICATION-STYLE.md  # chat/response rules
  skills/grill-me/, grilling/, handoff/  # skills
```

## Skills

| Skill | What it does |
| --- | --- |
| `grill-me` | Starts a grilling interview (calls `grilling`). |
| `grilling` | Interviews you until your plan or decision is fully thought through. |
| `handoff` | Summarizes the conversation so another agent can continue. |

## Install

Run the script for your operating system. Each script:

1. Creates the home `.claude/rules` and `.claude/skills` folders if they do not exist.
2. Copies `.claude/CLAUDE.md` to `~/.claude/CLAUDE.md` (`%USERPROFILE%\.claude\CLAUDE.md` on Windows).
3. Copies everything under `.claude/rules/` into `~/.claude/rules/`.
4. Copies everything under `.claude/skills/` into `~/.claude/skills/`.
5. Lists the installed files.

This makes the rules and skills apply to every project.

**This overwrites `~/.claude/CLAUDE.md` and any same-named files under `~/.claude/rules/` and `~/.claude/skills/`.**
Back those up first if you have your own. Other files in `~/.claude` are not touched.

The scripts locate the repo's `.claude` folder from their own path, so you can run them from any directory.

### Windows (PowerShell)

```powershell
.\.claude\installWindows.ps1
```

If execution policy blocks it:

```powershell
powershell -ExecutionPolicy Bypass -File .claude\installWindows.ps1
```

### macOS / Linux (bash or zsh)

```bash
bash .claude/installMacLinux.ps1
```