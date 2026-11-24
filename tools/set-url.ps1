<#
.SYNOPSIS
    Writes the GitHub Pages URL into the client CustomSkinLoader config.

.EXAMPLE
    .\set-url.ps1 -User nightwish -Repo mc-skins
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$User,
    [Parameter(Mandatory = $true)][string]$Repo
)

$ErrorActionPreference = 'Stop'
$site   = Split-Path -Parent $PSScriptRoot
$config = Join-Path (Split-Path -Parent $site) '_client_mods\CustomSkinLoader\CustomSkinLoader.json'
if (-not (Test-Path $config)) { throw "Config not found: $config" }

$url = "https://$User.github.io/$Repo/csl/"
$raw = [System.IO.File]::ReadAllText($config)
$new = [regex]::Replace($raw, '"root"\s*:\s*"https://[^"]*?/csl/"', '"root": "' + $url + '"')
[System.IO.File]::WriteAllText($config, $new, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Client config updated: $url" -ForegroundColor Green
Write-Host "Check after publishing: ${url}Nightwish.json" -ForegroundColor DarkGray
