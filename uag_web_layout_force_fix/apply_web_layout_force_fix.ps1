$ErrorActionPreference = 'Stop'
Write-Host "========================================"
Write-Host " UAG WEB LAYOUT FORCE FIX"
Write-Host "========================================"
Write-Host ""

$root = Get-Location
if (!(Test-Path "$root\pubspec.yaml")) {
  throw "Run this from project root: C:\Users\mikem\uag_traders_hub"
}

py .\tools\apply_web_layout_force_fix.py

Write-Host ""
Write-Host "DONE. Now run:"
Write-Host "flutter clean"
Write-Host "flutter pub get"
Write-Host "flutter analyze"
Write-Host "flutter run -d chrome"
