UAG ARC Tracker Asset Pipeline

Extract this ZIP directly into:
C:\Users\mikem\uag_traders_hub\

After extracting, you should have:
C:\Users\mikem\uag_traders_hub\run_arc_tracker_asset_pipeline.ps1
C:\Users\mikem\uag_traders_hub\tools\download_arc_tracker_items.py
C:\Users\mikem\uag_traders_hub\tools\arc_asset_pipeline_config.json

Run from PowerShell:
cd C:\Users\mikem\uag_traders_hub
powershell -ExecutionPolicy Bypass -File .\run_arc_tracker_asset_pipeline.ps1

This will:
- read the live GitHub repo data listed in tools\arc_asset_pipeline_config.json
- scrape https://arctracker.io/items using Playwright
- match only your app's real Scrappy / Bench / Quest / Trading item names
- crop inside the image border
- keep/bake a dark item-card background so assets do not look blank
- export 512x512 .webp files
- save into assets\arc_raiders\items\
- mirror assets to existing configured asset paths where needed
- write missing/duplicate/result reports

Do not delete old images until the app displays the new assets correctly.
