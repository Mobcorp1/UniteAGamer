UAG Emergency Firestore Restore

This restores your full firestore.rules and firestore.indexes.json from GitHub, then adds the missing uag_sessions permissions and indexes.

Run from PowerShell:

cd C:\Users\mikem\uag_traders_hub
powershell -ExecutionPolicy Bypass -File C:\Users\mikem\Downloads\uag_emergency_firestore_restore\restore_firestore_rules_and_sessions.ps1

Then deploy:

firebase deploy --only firestore:rules,firestore:indexes

Then test:

flutter clean
flutter pub get
flutter run -d chrome
