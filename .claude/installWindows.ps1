# Script for Windows PowerShell
# Copies CLAUDE.md and rules\ from this repo's .claude into %USERPROFILE%\.claude.
# Overwrites %USERPROFILE%\.claude\CLAUDE.md and same-named files under rules\.
$ErrorActionPreference = "Stop"

# Resolve the source from the script location so it works from any directory.
$src = $PSScriptRoot
$dest = Join-Path $env:USERPROFILE ".claude"

New-Item -ItemType Directory -Force -Path "$dest\rules" | Out-Null
Copy-Item -Path "$src\CLAUDE.md" -Destination $dest -Force
Copy-Item -Path "$src\rules\*" -Destination "$dest\rules" -Recurse -Force

Get-ChildItem -Recurse -File "$dest\CLAUDE.md", "$dest\rules" | Select-Object -ExpandProperty FullName
