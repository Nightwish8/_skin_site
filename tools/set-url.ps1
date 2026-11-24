<#
.SYNOPSIS
    Writes the skin site URL into the client CustomSkinLoader config.

.DESCRIPTION
    Two ways to call it:
      .\set-url.ps1 -Url https://user.github.io/repo/csl/
      .\set-url.ps1 -User nightwish8 -Repo _skin_site

    Only the first CustomSkinAPI entry (the "MC-Skins" one at the top of loadlist)
    is changed, so LittleSkin and other sources stay untouched.

.EXAMPLE
    .\set-url.ps1 -Url https://nightwish8.github.io/_skin_site/csl/
#>
[CmdletBinding(DefaultParameterSetName = 'Url')]
param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Url')][string]$Url,
    [Parameter(Mandatory = $true, ParameterSetName = 'UserRepo')][string]$User,
    [Parameter(Mandatory = $true, ParameterSetName = 'UserRepo')][string]$Repo
)

$ErrorActionPreference = 'Stop'
$site   = Split-Path -Parent $PSScriptRoot
$config = Join-Path (Split-Path -Parent $site) '_client_mods\CustomSkinLoader\CustomSkinLoader.json'
if (-not (Test-Path $config)) { throw "Config not found: $config" }

if ($PSCmdlet.ParameterSetName -eq 'UserRepo') {
    $Url = "https://$User.github.io/$Repo/csl/"
}
if (-not $Url.EndsWith('/')) { $Url += '/' }

$raw = [System.IO.File]::ReadAllText($config)
$m = [regex]::Match($raw, '"root"\s*:\s*"https?://[^"]*/csl/"')
if (-not $m.Success) { throw "No CustomSkinAPI root with /csl/ was found in $config" }

$new = $raw.Substring(0, $m.Index) + '"root": "' + $Url + '"' + $raw.Substring($m.Index + $m.Length)
[System.IO.File]::WriteAllText($config, $new, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Client config updated: $Url" -ForegroundColor Green
Write-Host "Check: ${Url}Nightwish.json" -ForegroundColor DarkGray
