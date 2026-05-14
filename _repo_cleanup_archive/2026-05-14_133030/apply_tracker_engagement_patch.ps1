Write-Host ""
Write-Host "========================================"
Write-Host " UAG TRACKER ENGAGEMENT + RESET PATCH"
Write-Host "========================================"
Write-Host ""

py tools\apply_tracker_engagement_patch.py

Write-Host ""
Write-Host "Patch complete. Next commands:"
Write-Host "flutter clean"
Write-Host "flutter pub get"
Write-Host "flutter analyze"
Write-Host "flutter run -d chrome"
Write-Host ""
pause
