<#
.SYNOPSIS
    Adds or updates a player skin in the static skin site (CustomSkinAPI + GitHub Pages).

.EXAMPLE
    .\add-skin.ps1 -Nick Nightwish -Skin C:\skins\nightwish.png

.EXAMPLE
    .\add-skin.ps1 -Nick Telekrafter -Skin C:\skins\tele.png -Cape C:\skins\tele_cape.png -Slim
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Nick,
    [Parameter(Mandatory = $true)][string]$Skin,
    [string]$Cape,
    [switch]$Slim
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

if ($Nick -notmatch '^[A-Za-z0-9_]{3,16}$') {
    throw "Nick '$Nick' does not look like a Minecraft username (3-16 chars: A-Z a-z 0-9 _)."
}

$site    = Split-Path -Parent $PSScriptRoot
$texDir  = Join-Path $site 'textures'
$cslDir  = Join-Path $site 'csl'
$players = Join-Path $site 'players.json'
New-Item -ItemType Directory -Path $texDir, $cslDir -Force | Out-Null

function Get-ImageSize([string]$Path) {
    $full = (Resolve-Path -LiteralPath $Path).Path
    $img  = [System.Drawing.Image]::FromFile($full)
    try { [pscustomobject]@{ Width = $img.Width; Height = $img.Height } }
    finally { $img.Dispose() }
}

function Add-Texture([string]$Path) {
    $full  = (Resolve-Path -LiteralPath $Path).Path
    $bytes = [System.IO.File]::ReadAllBytes($full)
    $sha   = [System.Security.Cryptography.SHA256]::Create()
    try { $hash = ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
    $dest = Join-Path $texDir ($hash + '.png')
    [System.IO.File]::WriteAllBytes($dest, $bytes)
    return ($hash + '.png')
}

# --- skin ---
$s = Get-ImageSize $Skin
if ($s.Width -ne $s.Height) { throw "Skin must be square, got $($s.Width)x$($s.Height)." }
if (($s.Width % 64) -ne 0 -or $s.Width -lt 64 -or $s.Width -gt 1024) {
    throw "Skin must be 64x64, 128x128, 256x256 ... (multiple of 64), got $($s.Width)x$($s.Height)."
}
$skinId = Add-Texture $Skin

# --- cape ---
$capeId = $null
if ($Cape) {
    $c = Get-ImageSize $Cape
    if (($c.Width % 64) -ne 0 -or ($c.Height % 32) -ne 0 -or ($c.Width / $c.Height) -ne 2) {
        throw "Cape must be 64x32, 128x64 and so on (width = 2 x height), got $($c.Width)x$($c.Height)."
    }
    $capeId = Add-Texture $Cape
}

# --- profile json ---
$textures = [ordered]@{}
if ($Slim) { $textures['slim'] = $skinId } else { $textures['default'] = $skinId }
if ($capeId) { $textures['cape'] = $capeId }
$profile = [ordered]@{ username = $Nick; textures = $textures }
$json = $profile | ConvertTo-Json -Depth 5
$out  = Join-Path $cslDir ($Nick + '.json')
[System.IO.File]::WriteAllText($out, $json, (New-Object System.Text.UTF8Encoding($false)))

# --- players.json ---
$list = New-Object System.Collections.ArrayList
if (Test-Path $players) {
    $raw = [System.IO.File]::ReadAllText($players)
    if ($raw.Trim()) {
        $parsed = $raw | ConvertFrom-Json
        foreach ($item in $parsed) { [void]$list.Add([string]$item) }
    }
}
if (-not $list.Contains($Nick)) {
    [void]$list.Add($Nick)
    $body = ($list | ForEach-Object { '  ' + (ConvertTo-Json ([string]$_) -Compress) }) -join ",`r`n"
    $text = "[`r`n$body`r`n]`r`n"
    [System.IO.File]::WriteAllText($players, $text, (New-Object System.Text.UTF8Encoding($false)))
}

Write-Host "OK: $Nick -> $skinId" -ForegroundColor Green
if ($capeId) { Write-Host "    cape -> $capeId" -ForegroundColor Green }
Write-Host "    model: $(if ($Slim) { 'slim' } else { 'default' })"
Write-Host ""
Write-Host "Next: git add . ; git commit -m ""skin: $Nick"" ; git push" -ForegroundColor Cyan
Write-Host "GitHub Pages updates in ~10 minutes; players restart their client." -ForegroundColor DarkGray
