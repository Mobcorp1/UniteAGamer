UAG Web Responsive Shell Patch

Extract this ZIP into:
C:\Users\mikem\uag_traders_hub\

It replaces:
web/index.html
web/manifest.json

Then run:
flutter clean
flutter pub get
flutter analyze
flutter build web --release
firebase deploy --only hosting

Then hard refresh the live site with Ctrl + F5.
