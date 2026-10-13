# Script for Windows PowerShell
# Copies CLAUDE.md, rules\, and skills\ from this repo's .claude into %USERPROFILE%\.claude.
# Overwrites %USERPROFILE%\.claude\CLAUDE.md and same-named files under rules\ and skills\.
$ErrorActionPreference = "Stop"

# Resolve the source from the script location so it works from any directory.
$src = $PSScriptRoot
$dest = Join-Path $env:USERPROFILE ".claude"

New-Item -ItemType Directory -Force -Path "$dest\rules", "$dest\skills" | Out-Null
Copy-Item -Path "$src\CLAUDE.md" -Destination $dest -Force
Copy-Item -Path "$src\rules\*" -Destination "$dest\rules" -Recurse -Force
Copy-Item -Path "$src\skills\*" -Destination "$dest\skills" -Recurse -Force

Get-ChildItem -Recurse -File "$dest\CLAUDE.md", "$dest\rules", "$dest\skills" | Select-Object -ExpandProperty FullName
