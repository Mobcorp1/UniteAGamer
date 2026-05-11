$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "======================================="
Write-Host " UAG ARC TRACKER ASSET PIPELINE"
Write-Host " Playwright rendered scraper upgrade"
Write-Host "======================================="
Write-Host ""

if (-not (Test-Path "tools\download_arc_tracker_items.py")) {
  Write-Host "ERROR: tools\download_arc_tracker_items.py not found."
  Write-Host "Extract this ZIP directly into C:\Users\mikem\uag_traders_hub so the tools folder sits inside the project root."
  exit 1
}

if (-not (Test-Path "tools\arc_asset_pipeline_config.json")) {
  Write-Host "ERROR: tools\arc_asset_pipeline_config.json not found."
  Write-Host "Extract this ZIP directly into C:\Users\mikem\uag_traders_hub so the tools folder sits inside the project root."
  exit 1
}

Write-Host "Installing/updating Python dependencies..."
py -m pip install --upgrade requests pillow beautifulsoup4 playwright

Write-Host "Installing Chromium for Playwright..."
py -m playwright install chromium

Write-Host "Running asset pipeline..."
py tools\download_arc_tracker_items.py --debug-screenshot

Write-Host ""
Write-Host "======================================="
Write-Host " PIPELINE COMPLETE"
Write-Host " Check: assets\arc_raiders\items"
Write-Host " Check: assets\arc_raiders\items\missing_asset_report.json"
Write-Host " Check: assets\arc_raiders\items\arc_item_download_results.json"
Write-Host "======================================="
Write-Host ""

pause
