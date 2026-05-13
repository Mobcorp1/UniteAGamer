UAG WEB LEFT-SIDE LAYOUT FIX

Extract this ZIP into:
C:\Users\mikem\uag_traders_hub\

Run:
powershell -ExecutionPolicy Bypass -File .\apply_stackfit_expand_patch.ps1

Then:
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome

If Chrome looks correct:
flutter build web --release
firebase deploy --only hosting

Then open live site with cache bust:
https://YOUR-SITE.web.app/?v=stackfix1

What this fixes:
Several app screens use Stack + Positioned.fill watermarks. Flutter Stack defaults to StackFit.loose, which can shrink the actual Stack to the width of the non-positioned content on web. That makes the whole UI look like it is stuck on the left side with the rest of the browser as plain dark background.

This patch adds:
fit: StackFit.expand

to the affected Stack widgets and adds a defensive fullscreen web guard in web/index.html.
