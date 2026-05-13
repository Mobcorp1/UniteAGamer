UAG Arc Raiders Hub FULL NAMING UPDATE

Target app name:
UAG Arc Raiders Hub

This package updates inconsistent naming across the Flutter app and web metadata.

It replaces:
- UIG Riders Hub
- UIG Traders Hub
- UIG Raiders Hub
- UAG Arc Raiders Hub
- UAG Riders Hub
- UAG Arc Raiders Hub
- Arc Riders Trading Hub
- Arc Raiders Trading Hub
- ARC Raiders Trading Hub
- Raiders Hub

With:
UAG Arc Raiders Hub

It also forces:
- MaterialApp title
- web/index.html browser title
- web/manifest.json app name and short name
- pubspec.yaml description

Run from PowerShell:

cd C:\Users\mikem\uag_traders_hub
powershell -ExecutionPolicy Bypass -File C:\Users\mikem\Downloads\uag_arc_raiders_hub_full_naming_update\apply_uag_arc_raiders_hub_full_naming_update.ps1

Then:

flutter clean
flutter pub get
flutter analyze
flutter build web --release
firebase deploy --only hosting
