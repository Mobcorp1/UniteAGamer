# UAG Voice + Session Planner Patch

Extract into C:\Users\mikem\uag_traders_hub\ and run:

powershell -ExecutionPolicy Bypass -File .\apply_voice_session_planner_patch.ps1
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
