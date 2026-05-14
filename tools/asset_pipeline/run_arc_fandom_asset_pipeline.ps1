Write-Host ""
Write-Host "========================================"
Write-Host " UAG ARC RAIDERS FANDOM ASSET PIPELINE"
Write-Host "========================================"
Write-Host ""

if (!(Test-Path "tools\download_arc_fandom_assets.py")) {
  Write-Host "ERROR: tools\download_arc_fandom_assets.py not found. Extract this ZIP into the project root." -ForegroundColor Red
  pause
  exit 1
}

py -m pip install --upgrade requests pillow beautifulsoup4

py tools\download_arc_fandom_assets.py

Write-Host ""
Write-Host "========================================"
Write-Host " PIPELINE COMPLETE"
Write-Host "========================================"
Write-Host "Check: assets\arc_raiders\items\missing_asset_report.json"
Write-Host ""
pause
