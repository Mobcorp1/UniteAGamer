UAG Session Planner Targeted Firestore Rules Fix

This does NOT replace your whole firestore.rules file.

It only:
- backs up firestore.rules
- replaces or inserts the /uag_sessions/{sessionId} rule
- writes UTF-8 without BOM

Run from PowerShell:

cd C:\Users\mikem\uag_traders_hub
powershell -ExecutionPolicy Bypass -File .\uag_session_rules_targeted_fix\apply_uag_session_rules_targeted_fix.ps1
firebase deploy --only firestore:rules

Then test Session Planner again.
