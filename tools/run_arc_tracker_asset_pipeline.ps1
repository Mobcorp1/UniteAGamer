$ErrorActionPreference = "Stop"

Write-Host "UAG ARCTracker item asset pipeline" -ForegroundColor Cyan
Write-Host "Run this from your project root: C:\Users\mikem\uag_traders_hub" -ForegroundColor Yellow

py -m pip install --upgrade pip
py -m pip install requests pillow beautifulsoup4 playwright
py -m playwright install chromium

py tools\download_arc_tracker_items.py

Write-Host "Done. Check assets\arc_raiders\items\missing_asset_report.json" -ForegroundColor Green
