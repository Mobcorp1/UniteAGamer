UAG Tracker Engagement Patch

Extract this ZIP directly into:
C:\Users\mikem\uag_traders_hub\

Then run:
powershell -ExecutionPolicy Bypass -File .\apply_tracker_engagement_patch.ps1

What it changes:
1. Blueprint drop reports no longer add duplicate counts automatically.
   - A drop report marks the blueprint as owned.
   - Duplicate count only changes when the user explicitly enters duplicate count/adds dupes.

2. Blueprint Tracker gets a Share Missing button.
   - Uses native share sheet, so WhatsApp appears if installed.

3. Scrappy / Bench / Quest trackers get visible reset + share actions.
   - Share sends the current tracker missing list with remaining quantities.
   - Reset resets only the current tracker mode.

After patch:
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
