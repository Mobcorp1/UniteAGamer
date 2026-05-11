Write-Host ""
Write-Host "======================================="
Write-Host " UAG ARC TRACKER ASSET PIPELINE"
Write-Host "======================================="
Write-Host ""

if (-not (Test-Path "tools\download_arc_tracker_items.py")) {
  Write-Host "ERROR: tools\download_arc_tracker_items.py not found. Extract this ZIP into your project root: C:\Users\mikem\uag_traders_hub"
  pause
  exit 1
}

if (-not (Test-Path "tools\arc_asset_pipeline_config.json")) {
  Write-Host "ERROR: tools\arc_asset_pipeline_config.json not found. Extract this ZIP into your project root: C:\Users\mikem\uag_traders_hub"
  pause
  exit 1
}

py -m pip install requests pillow beautifulsoup4 playwright
if ($LASTEXITCODE -ne 0) { pause; exit $LASTEXITCODE }

py -m playwright install chromium
if ($LASTEXITCODE -ne 0) { pause; exit $LASTEXITCODE }

py tools\download_arc_tracker_items.py
$pipelineExit = $LASTEXITCODE

Write-Host ""
Write-Host "======================================="
Write-Host " PIPELINE COMPLETE"
Write-Host "======================================="
Write-Host ""
Write-Host "Output folder: assets\arc_raiders\items"
Write-Host "Reports:"
Write-Host " - assets\arc_raiders\items\arc_item_reference_manifest.json"
Write-Host " - assets\arc_raiders\items\arc_item_download_results.json"
Write-Host " - assets\arc_raiders\items\missing_asset_report.json"
Write-Host " - assets\arc_raiders\items\duplicate_asset_report.json"
Write-Host ""

pause
exit $pipelineExit
