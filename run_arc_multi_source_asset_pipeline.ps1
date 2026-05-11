$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " UAG ARC MULTI-SOURCE ASSET PIPELINE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
py -m pip install --upgrade pip
py -m pip install requests pillow beautifulsoup4 playwright

Write-Host ""
Write-Host "Installing Playwright Chromium..." -ForegroundColor Yellow
py -m playwright install chromium

Write-Host ""
Write-Host "Running asset pipeline..." -ForegroundColor Yellow
py tools\download_arc_multi_source_assets.py

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " PIPELINE COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Check: assets\arc_raiders\items" -ForegroundColor Cyan
Write-Host "Check reports in: assets\arc_raiders\items\_reports" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to close"
