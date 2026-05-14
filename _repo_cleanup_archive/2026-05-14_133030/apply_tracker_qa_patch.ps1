Write-Host ""
Write-Host "========================================"
Write-Host " UAG TRACKER QA PATCH"
Write-Host "========================================"
Write-Host ""

py tools\apply_tracker_qa_patch.py

if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "PATCH FAILED - no build commands have been run." -ForegroundColor Red
  Write-Host "Send the output above back to Neo."
  exit $LASTEXITCODE
}

Write-Host ""
Write-Host "PATCH COMPLETE"
Write-Host "Next commands:"
Write-Host "flutter clean"
Write-Host "flutter pub get"
Write-Host "flutter analyze"
Write-Host "flutter run -d chrome"
Write-Host ""
