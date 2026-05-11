UAG ARC RAIDERS LOOT ASSET PIPELINE

WHAT THIS PACKAGE DOES
- Uses your live GitHub repo as the reference source of truth.
- Uses https://arcraiders.wiki/wiki/Loot as the new primary image source.
- Downloads item images for Scrappy Tracker, Bench Tracker, Quest Tracker and Trading Hub items.
- Converts everything to .webp.
- Saves into assets/arc_raiders/items/.
- Mirrors into assets/arc_raiders/scrappy_resources/ as well, because older tracker code may still point there.
- Automatically patches pubspec.yaml to include assets/arc_raiders/items/.
- Supports manual override images.

INSTALL
1. Extract this ZIP directly into:
   C:\Users\mikem\uag_traders_hub\

After extraction you should have:
   C:\Users\mikem\uag_traders_hub\run_arc_loot_asset_pipeline.ps1
   C:\Users\mikem\uag_traders_hub\tools\download_arc_loot_assets.py
   C:\Users\mikem\uag_traders_hub\tools\arc_loot_asset_pipeline_config.json
   C:\Users\mikem\uag_traders_hub\assets\arc_raiders\manual_overrides\

RUN
Open PowerShell:
   cd C:\Users\mikem\uag_traders_hub
   powershell -ExecutionPolicy Bypass -File .\run_arc_loot_asset_pipeline.ps1

OUTPUT
Generated images:
   assets\arc_raiders\items\
   assets\arc_raiders\scrappy_resources\

Reports:
   assets\arc_raiders\items\arc_item_reference_manifest.json
   assets\arc_raiders\items\arcraiders_wiki_loot_catalogue.json
   assets\arc_raiders\items\arc_item_download_results.json
   assets\arc_raiders\items\missing_asset_report.json
   assets\arc_raiders\items\duplicate_asset_report.json

MANUAL OVERRIDES
For items that still need manual images, drop a .webp/.png/.jpg into:
   assets\arc_raiders\manual_overrides\

Use either the item name slug or item id slug.
Examples:
   mixed_fruit.webp
   fruit_mix.webp
   agave.webp
   very_comfortable_pillows.webp

Then run the pipeline again. Manual overrides always win.

AFTER PIPELINE
Run:
   flutter clean
   flutter pub get
   flutter build web
   firebase deploy --only hosting

IMPORTANT
This package does NOT touch blueprint assets.
