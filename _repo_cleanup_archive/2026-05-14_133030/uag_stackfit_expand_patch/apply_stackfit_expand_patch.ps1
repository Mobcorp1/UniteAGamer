Write-Host ""
Write-Host "========================================"
Write-Host " UAG WEB STACK FULL-WIDTH FIX"
Write-Host "========================================"
Write-Host ""

py tools\apply_stackfit_expand_patch.py

Write-Host ""
Write-Host "Next commands:"
Write-Host "flutter clean"
Write-Host "flutter pub get"
Write-Host "flutter analyze"
Write-Host "flutter run -d chrome"
Write-Host ""
pause
