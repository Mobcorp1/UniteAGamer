Write-Host ""
Write-Host "========================================"
Write-Host " UAG WEB FULL WIDTH GUARD PATCH"
Write-Host "========================================"
Write-Host ""

py tools\apply_web_full_width_guard.py

Write-Host ""
Write-Host "Next commands:"
Write-Host "flutter clean"
Write-Host "flutter pub get"
Write-Host "flutter analyze"
Write-Host "flutter build web --release"
Write-Host "firebase deploy --only hosting"
Write-Host ""
pause
