Write-Host ""
Write-Host "========================================"
Write-Host " UAG VOICE + SESSION PLANNER ROUTE FIX"
Write-Host "========================================"
Write-Host ""

py tools\apply_voice_session_route_fix.py

if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "PATCH FAILED - paste the terminal output back into ChatGPT."
  exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Patch complete. Next commands:"
Write-Host "flutter clean"
Write-Host "flutter pub get"
Write-Host "flutter analyze"
Write-Host "flutter run -d chrome"
Write-Host ""
