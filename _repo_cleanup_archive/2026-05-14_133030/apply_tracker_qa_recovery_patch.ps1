Write-Host ""
Write-Host "========================================"
Write-Host " UAG TRACKER QA RECOVERY PATCH"
Write-Host "========================================"
Write-Host ""

py tools\apply_tracker_qa_recovery_patch.py

if ($LASTEXITCODE -ne 0) {
  Write-Host ""
  Write-Host "PATCH FAILED - do not run Flutter until the error above is fixed." -ForegroundColor Red
  exit $LASTEXITCODE
}

Write-Host ""
Write-Host "Patch complete. Next commands:"
Write-Host "flutter clean"
Write-Host "flutter pub get"
Write-Host "flutter analyze"
Write-Host "flutter run -d chrome"
Write-Host ""
