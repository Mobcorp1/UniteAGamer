# UAG ARC Raiders Multi-Source Asset Pipeline

This package replaces the single-source item downloader with a multi-source pipeline.

It does **not** touch blueprint assets.

It covers:
- Scrappy Tracker
- Bench Tracker
- Quest Tracker
- Trading Hub item assets
- Item images from multiple web sources
- Local manual overrides
- WebP output
- Missing reports

## Sources used

Priority order:

1. `assets/arc_raiders/manual_overrides/`
2. `https://arctracker.io/items`
3. `https://arc-raiders.fandom.com/wiki/Items`
4. `https://thearcraiders.wiki/items`
5. `https://arcraidershub.com/needed-items-recycling-guide`
6. Generated placeholder if still missing

## Install

Extract this ZIP directly into:

```text
C:\Users\mikem\uag_traders_hub\
```

You should end up with:

```text
C:\Users\mikem\uag_traders_hub\run_arc_multi_source_asset_pipeline.ps1
C:\Users\mikem\uag_traders_hub\tools\download_arc_multi_source_assets.py
C:\Users\mikem\uag_traders_hub\tools\arc_multi_source_asset_config.json
```

## Run

```powershell
cd C:\Users\mikem\uag_traders_hub
powershell -ExecutionPolicy Bypass -File .\run_arc_multi_source_asset_pipeline.ps1
```

## Output

Images:

```text
assets\arc_raiders\items\
```

Reports:

```text
assets\arc_raiders\items\_reports\
```

Important reports:

```text
arc_item_download_results.json
missing_asset_report.json
combined_source_catalogue.json
duplicate_asset_report.json
```

## Manual override system

For any image still wrong/missing, put a manually sourced image here:

```text
assets\arc_raiders\manual_overrides\
```

Use either item ID or slugged display name, for example:

```text
dog_collar.png
dog_collar.webp
very_comfortable_pillows.png
industrial_batteries.webp
```

The pipeline will use manual overrides first and convert them to the final WebP output.

## After running

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

Check:
- Scrappy Tracker
- Bench Tracker
- Quest Tracker
- Trading Hub item selector

Deploy:

```powershell
flutter build web
firebase deploy --only hosting
```
