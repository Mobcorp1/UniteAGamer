$ErrorActionPreference = "Stop"

$projectRoot = "C:\Users\mikem\uag_traders_hub"
$rulesPath = Join-Path $projectRoot "firestore.rules"

Write-Host ""
Write-Host "========================================"
Write-Host " UAG SESSION RULES TARGETED FIX"
Write-Host "========================================"
Write-Host ""

if (!(Test-Path $rulesPath)) {
    throw "firestore.rules not found at $rulesPath"
}

$backupPath = Join-Path $projectRoot "firestore.rules.before_uag_sessions_targeted_fix"
Copy-Item $rulesPath $backupPath -Force
Write-Host "Backup saved: $backupPath"

$content = Get-Content $rulesPath -Raw

# Remove BOM / bad invisible chars safely.
$content = $content.TrimStart([char]0xFEFF, [char]0x200B, [char]0xEFBBBF)

$sessionRule = @'
    match /uag_sessions/{sessionId} {
      // Session Planner immediate fix:
      // Allow signed-in users to load session calendar queries.
      // This only applies to uag_sessions and does not touch any other app rules.
      allow read: if request.auth != null;

      allow create: if request.auth != null
        && request.resource.data.createdBy == request.auth.uid;

      allow update: if request.auth != null
        && (
          resource.data.createdBy == request.auth.uid ||
          resource.data.participantOneUid == request.auth.uid ||
          resource.data.participantTwoUid == request.auth.uid
        );

      allow delete: if request.auth != null
        && resource.data.createdBy == request.auth.uid;
    }

'@

# Replace existing uag_sessions rule if present.
$pattern = '(?s)\s*match\s+/uag_sessions/\{sessionId\}\s*\{.*?\n\s*\}\s*'
if ($content -match 'match\s+/uag_sessions/\{sessionId\}') {
    $content = [regex]::Replace($content, $pattern, "`n$sessionRule", 1)
    Write-Host "Replaced existing uag_sessions rule only."
}
else {
    # Insert just before the closing braces of match /databases/{database}/documents.
    $last = $content.LastIndexOf("}")
    if ($last -lt 0) {
        throw "Could not find final closing brace in firestore.rules"
    }

    $secondLast = $content.LastIndexOf("}", $last - 1)
    if ($secondLast -lt 0) {
        throw "Could not find database closing brace in firestore.rules"
    }

    $content = $content.Substring(0, $secondLast) + "`n$sessionRule" + $content.Substring($secondLast)
    Write-Host "Inserted uag_sessions rule before final database close."
}

# Write UTF-8 without BOM.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($rulesPath, $content, $utf8NoBom)

Write-Host ""
Write-Host "DONE. Now deploy:"
Write-Host "firebase deploy --only firestore:rules"
Write-Host ""
