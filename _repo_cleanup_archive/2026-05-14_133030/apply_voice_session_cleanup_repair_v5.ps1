Write-Host ""
Write-Host "========================================"
Write-Host " UAG VOICE + SESSION CLEANUP REPAIR V5"
Write-Host "========================================"
Write-Host ""

py tools\repair_voice_session_cleanup_v5.py

Write-Host ""
Write-Host "Next commands:"
Write-Host "flutter clean"
Write-Host "flutter pub get"
Write-Host "flutter analyze"
Write-Host "flutter run -d chrome"
Write-Host ""
pause
