# Script for Windows PowerShell
# Copies CLAUDE.md, rules\, and skills\ from this repo's .claude into %USERPROFILE%\.claude.
# Overwrites %USERPROFILE%\.claude\CLAUDE.md and same-named files under rules\ and skills\.
# Creates %USERPROFILE%\.claude\settings.json from settings.template.json, or merges the template into it:
# template scalars and enabledPlugins overwrite, permissions.deny is a union, other keys are kept.
$ErrorActionPreference = "Stop"

# Resolve the source from the script location so it works from any directory.
$src = $PSScriptRoot
$dest = Join-Path $env:USERPROFILE ".claude"

New-Item -ItemType Directory -Force -Path "$dest\rules", "$dest\skills" | Out-Null
Copy-Item -Path "$src\CLAUDE.md" -Destination $dest -Force
Copy-Item -Path "$src\rules\*" -Destination "$dest\rules" -Recurse -Force
Copy-Item -Path "$src\skills\*" -Destination "$dest\skills" -Recurse -Force

$template = Join-Path $src "settings.template.json"
$settings = Join-Path $dest "settings.json"

if (-not (Test-Path $settings)) {
    Copy-Item -Path $template -Destination $settings
} else {
    try {
        $tpl = Get-Content -Raw $template | ConvertFrom-Json
        $cur = Get-Content -Raw $settings | ConvertFrom-Json

        foreach ($prop in $tpl.PSObject.Properties) {
            if ($prop.Name -eq "permissions") { continue }
            Add-Member -InputObject $cur -NotePropertyName $prop.Name -NotePropertyValue $prop.Value -Force
        }

        # Union, not overwrite, so deny rules already on this machine are kept.
        if (-not $cur.permissions) {
            Add-Member -InputObject $cur -NotePropertyName "permissions" -NotePropertyValue ([pscustomobject]@{}) -Force
        }
        $deny = @(@($cur.permissions.deny) + @($tpl.permissions.deny)) | Where-Object { $_ } | Select-Object -Unique
        Add-Member -InputObject $cur.permissions -NotePropertyName "deny" -NotePropertyValue @($deny) -Force

        # WriteAllText avoids the BOM that Windows PowerShell 5.1 adds with Set-Content -Encoding UTF8.
        $json = $cur | ConvertTo-Json -Depth 100
        [System.IO.File]::WriteAllText($settings, $json, (New-Object System.Text.UTF8Encoding $false))
    } catch {
        Write-Warning "Skipped settings.json merge, file left unchanged: $_"
    }
}

Get-ChildItem -Recurse -File "$dest\CLAUDE.md", "$dest\rules", "$dest\skills" | Select-Object -ExpandProperty FullName
if (Test-Path $settings) { $settings }
