$ErrorActionPreference = "Stop"

if (-not (Test-Path "pubspec.yaml")) {
  Write-Host "Run this from the Flutter project root, e.g. C:\Users\mikem\uag_traders_hub" -ForegroundColor Red
  exit 1
}

$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
  $python = Get-Command py -ErrorAction SilentlyContinue
}
if (-not $python) {
  Write-Host "Python was not found. Install Python 3, then run this again." -ForegroundColor Red
  exit 1
}

Write-Host "Installing/updating required Python packages..." -ForegroundColor Cyan
python -m pip install --upgrade requests pillow beautifulsoup4

Write-Host "Downloading real ARC Raiders WebP resource assets..." -ForegroundColor Cyan
python .\tools\download_arc_resource_assets.py

Write-Host "Done. Check assets\arc_raiders\scrappy_resources\missing_asset_report.json if any items still miss." -ForegroundColor Green
