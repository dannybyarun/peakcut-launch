# Starts PeakCut locally. Double-click this file, or run: .\start-peakcut.ps1
#
# The app comes up at http://127.0.0.1:8765/app

$ErrorActionPreference = "Stop"
$root = $PSScriptRoot
$venv = Join-Path $root "peakcut\.venv\Scripts\python.exe"

if (-not (Test-Path $venv)) {
    Write-Host "The Python environment is missing. Create it once with:" -ForegroundColor Yellow
    Write-Host "  C:\Python313\python.exe -m venv peakcut\.venv"
    Write-Host "  peakcut\.venv\Scripts\python.exe -m pip install -r peakcut\requirements.txt"
    exit 1
}

$env:PEAKCUT_DATA       = Join-Path $root "peakcut\data"
$env:PYTHONIOENCODING  = "utf-8"          # the app prints text the Windows console cannot show otherwise
$env:PEAKCUT_PUBLIC_URL = "http://127.0.0.1:8765"
# At most three streams recorded at once. Each one keeps ten minutes of video on disk, so this
# is also the cap on how much space the recordings take (about 300 MB each).
$env:PEAKCUT_MAX_LIVE  = "3"

Set-Location (Join-Path $root "peakcut")
& $venv -m studio.server
