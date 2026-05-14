Write-Host ""
Write-Host "========================================"
Write-Host " UAG ARC RAIDERS LOOT ASSET PIPELINE"
Write-Host "========================================"
Write-Host ""

if (!(Test-Path "tools\download_arc_loot_assets.py")) {
  Write-Host "ERROR: tools\download_arc_loot_assets.py not found."
  Write-Host "Extract this ZIP directly into C:\Users\mikem\uag_traders_hub\"
  pause
  exit 1
}

if (!(Test-Path "tools\arc_loot_asset_pipeline_config.json")) {
  Write-Host "ERROR: tools\arc_loot_asset_pipeline_config.json not found."
  Write-Host "Extract this ZIP directly into C:\Users\mikem\uag_traders_hub\"
  pause
  exit 1
}

Write-Host "Installing Python dependencies..."
py -m pip install requests beautifulsoup4 pillow

Write-Host ""
Write-Host "Running asset pipeline..."
py tools\download_arc_loot_assets.py

Write-Host ""
Write-Host "========================================"
Write-Host " PIPELINE COMPLETE"
Write-Host "========================================"
Write-Host ""
Write-Host "Check: assets\arc_raiders\items\"
Write-Host "Check: assets\arc_raiders\items\missing_asset_report.json"
Write-Host ""
pause
