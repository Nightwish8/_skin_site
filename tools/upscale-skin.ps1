<#
.SYNOPSIS
    Upscales a 64x64 skin to 128x128 / 256x256 with nearest-neighbour (pixel-perfect).

.DESCRIPTION
    Java HD skins keep the same 64x64 layout, just scaled by a whole factor.
    Nearest-neighbour keeps every pixel sharp, but it does NOT add detail:
    a 64x64 skin upscaled to 256x256 looks exactly the same in game.

.EXAMPLE
    .\upscale-skin.ps1 -In C:\skins\hero.png -Out C:\skins\hero_256.png -Factor 4
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$In,
    [Parameter(Mandatory = $true)][string]$Out,
    [ValidateSet(2, 4, 8)][int]$Factor = 4
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Bitmap]::FromFile((Resolve-Path -LiteralPath $In).Path)
try {
    if ($src.Width -ne 64 -or $src.Height -ne 64) {
        Write-Warning "Source is $($src.Width)x$($src.Height), expected 64x64. Layout may break."
    }
    $w = $src.Width * $Factor
    $h = $src.Height * $Factor
    $dst = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($dst)
    try {
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
        $g.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
        $g.DrawImage($src, 0, 0, $w, $h)
    }
    finally { $g.Dispose() }
    $target = if ([System.IO.Path]::IsPathRooted($Out)) { $Out } else { Join-Path (Get-Location).Path $Out }
    $dst.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
    $dst.Dispose()
    Write-Host "Saved ${w}x${h}: $target" -ForegroundColor Green
}
finally { $src.Dispose() }
