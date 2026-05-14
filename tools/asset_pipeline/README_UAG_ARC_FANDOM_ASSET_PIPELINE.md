# UAG ARC Raiders Fandom Asset Pipeline

Extract this ZIP directly into:

`C:\Users\mikem\uag_traders_hub\`

You should then have:

- `run_arc_fandom_asset_pipeline.ps1`
- `tools/download_arc_fandom_assets.py`
- `tools/arc_fandom_asset_config.json`

Run:

```powershell
cd C:\Users\mikem\uag_traders_hub
powershell -ExecutionPolicy Bypass -File .\run_arc_fandom_asset_pipeline.ps1
```

Outputs:

- `assets/arc_raiders/items/*.webp`
- `assets/arc_raiders/items/arc_item_reference_manifest.json`
- `assets/arc_raiders/items/fandom_raw_image_catalogue.json`
- `assets/arc_raiders/items/arc_item_download_results.json`
- `assets/arc_raiders/items/missing_asset_report.json`
- `assets/arc_raiders/items/duplicate_asset_report.json`

Then run:

```powershell
flutter clean
flutter pub get
flutter run -d chrome
```

Deploy:

```powershell
flutter build web
firebase deploy --only hosting
```
