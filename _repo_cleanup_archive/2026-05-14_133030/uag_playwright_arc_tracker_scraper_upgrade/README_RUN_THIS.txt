UAG ARCTracker Asset Pipeline — Playwright Rendered Scraper Upgrade

WHAT THIS ZIP DOES
- Replaces the broken static/partial scraper.
- Uses Playwright Chromium to open https://arctracker.io/items as a rendered page.
- Reads your live GitHub repo data as the item source of truth.
- Excludes blueprints.
- Downloads Scrappy / Bench / Quest / Trading item images.
- Keeps the item background instead of blank transparency.
- Crops inside the frame.
- Enlarges assets so small fruit items do not look tiny.
- Converts everything to .webp.
- Writes reports.

INSTALL
1. Extract this ZIP directly into:
   C:\Users\mikem\uag_traders_hub\

2. You should then have:
   C:\Users\mikem\uag_traders_hub\run_arc_tracker_asset_pipeline.ps1
   C:\Users\mikem\uag_traders_hub\tools\download_arc_tracker_items.py
   C:\Users\mikem\uag_traders_hub\tools\arc_asset_pipeline_config.json

RUN
Open PowerShell:

   cd C:\Users\mikem\uag_traders_hub
   powershell -ExecutionPolicy Bypass -File .\run_arc_tracker_asset_pipeline.ps1

OUTPUT
Images:
   assets\arc_raiders\items\*.webp

Reports:
   assets\arc_raiders\items\arc_item_reference_manifest.json
   assets\arc_raiders\items\arctracker_rendered_catalogue.json
   assets\arc_raiders\items\arc_item_download_results.json
   assets\arc_raiders\items\missing_asset_report.json
   assets\arc_raiders\items\duplicate_asset_report.json

IF IT STILL MISSES EVERYTHING
Run this debug command:

   py tools\download_arc_tracker_items.py --keep-browser-open --debug-screenshot

Then send:
   assets\arc_raiders\items\arctracker_debug_page.png
   assets\arc_raiders\items\arctracker_rendered_catalogue.json
   assets\arc_raiders\items\missing_asset_report.json
