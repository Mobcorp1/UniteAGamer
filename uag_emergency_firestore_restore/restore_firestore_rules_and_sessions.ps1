$ErrorActionPreference = "Stop"

$projectRoot = "C:\Users\mikem\uag_traders_hub"
$rulesUrl = "https://raw.githubusercontent.com/Mobcorp1/UniteAGamer/main/firestore.rules"
$indexesUrl = "https://raw.githubusercontent.com/Mobcorp1/UniteAGamer/main/firestore.indexes.json"

Write-Host ""
Write-Host "========================================"
Write-Host " UAG EMERGENCY FIRESTORE RULES RESTORE"
Write-Host "========================================"
Write-Host ""

if (!(Test-Path "$projectRoot\pubspec.yaml")) {
    throw "Project root not found: $projectRoot"
}

$backupRoot = Join-Path $projectRoot "_firestore_emergency_backup"
if (Test-Path $backupRoot) {
    Remove-Item -Recurse -Force $backupRoot
}
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

$rulesPath = Join-Path $projectRoot "firestore.rules"
$indexesPath = Join-Path $projectRoot "firestore.indexes.json"

if (Test-Path $rulesPath) {
    Copy-Item $rulesPath (Join-Path $backupRoot "firestore.rules.before_emergency_restore") -Force
}

if (Test-Path $indexesPath) {
    Copy-Item $indexesPath (Join-Path $backupRoot "firestore.indexes.json.before_emergency_restore") -Force
}

Write-Host "Downloading live GitHub firestore.rules..."
$rules = (Invoke-WebRequest -Uri $rulesUrl -UseBasicParsing).Content

$uagSessionsRule = @"
match /uag_sessions/{sessionId} {
  allow read: if request.auth != null
    && (
      resource.data.participantOneUid == request.auth.uid ||
      resource.data.participantTwoUid == request.auth.uid ||
      resource.data.createdBy == request.auth.uid ||
      isAdminOrDev()
    );

  allow create: if request.auth != null
    && request.resource.data.createdBy == request.auth.uid
    && (
      request.resource.data.participantOneUid == request.auth.uid ||
      request.resource.data.participantTwoUid == request.auth.uid ||
      isAdminOrDev()
    );

  allow update: if request.auth != null
    && (
      resource.data.participantOneUid == request.auth.uid ||
      resource.data.participantTwoUid == request.auth.uid ||
      resource.data.createdBy == request.auth.uid ||
      isAdminOrDev()
    );

  allow delete: if request.auth != null
    && (
      resource.data.createdBy == request.auth.uid ||
      isAdminOrDev()
    );
}
"@

if ($rules -notmatch "match\s+/uag_sessions/\{sessionId\}") {
    if ($rules -match "match\s+/sessions/\{sessionId\}") {
        $rules = $rules -replace "match\s+/sessions/\{sessionId\}", ($uagSessionsRule + " match /sessions/{sessionId}")
        Write-Host "Inserted uag_sessions rules before existing sessions rules."
    } else {
        $insert = $uagSessionsRule + " } }"
        $last = $rules.LastIndexOf("} }")
        if ($last -lt 0) {
            throw "Could not find safe insertion point in firestore.rules"
        }
        $rules = $rules.Substring(0, $last) + $insert + $rules.Substring($last + 3)
        Write-Host "Inserted uag_sessions rules before final closing braces."
    }
} else {
    Write-Host "uag_sessions rule already present."
}

Set-Content -Path $rulesPath -Value $rules -Encoding UTF8
Write-Host "Wrote restored firestore.rules"

Write-Host "Downloading live GitHub firestore.indexes.json..."
$indexesText = (Invoke-WebRequest -Uri $indexesUrl -UseBasicParsing).Content
$indexes = $indexesText | ConvertFrom-Json

if ($null -eq $indexes.indexes) {
    $indexes | Add-Member -MemberType NoteProperty -Name indexes -Value @()
}

function Has-UagSessionIndex($fieldName) {
    foreach ($idx in $indexes.indexes) {
        if ($idx.collectionGroup -eq "uag_sessions") {
            if ($idx.fields.Count -ge 2) {
                if ($idx.fields[0].fieldPath -eq $fieldName -and $idx.fields[1].fieldPath -eq "scheduledAt") {
                    return $true
                }
            }
        }
    }
    return $false
}

function New-UagSessionIndex($fieldName) {
    return [pscustomobject]@{
        collectionGroup = "uag_sessions"
        queryScope = "COLLECTION"
        fields = @(
            [pscustomobject]@{
                fieldPath = $fieldName
                order = "ASCENDING"
            },
            [pscustomobject]@{
                fieldPath = "scheduledAt"
                order = "ASCENDING"
            }
        )
    }
}

$newIndexes = @()
foreach ($idx in $indexes.indexes) {
    $newIndexes += $idx
}

if (!(Has-UagSessionIndex "participantOneUid")) {
    $newIndexes += New-UagSessionIndex "participantOneUid"
    Write-Host "Added uag_sessions participantOneUid + scheduledAt index."
}

if (!(Has-UagSessionIndex "participantTwoUid")) {
    $newIndexes += New-UagSessionIndex "participantTwoUid"
    Write-Host "Added uag_sessions participantTwoUid + scheduledAt index."
}

$indexes.indexes = $newIndexes

$indexes | ConvertTo-Json -Depth 100 | Set-Content -Path $indexesPath -Encoding UTF8
Write-Host "Wrote restored firestore.indexes.json"

Write-Host ""
Write-Host "========================================"
Write-Host " RESTORE COMPLETE"
Write-Host "========================================"
Write-Host ""
Write-Host "NOW RUN THIS:"
Write-Host "firebase deploy --only firestore:rules,firestore:indexes"
Write-Host ""
Write-Host "THEN TEST:"
Write-Host "flutter clean"
Write-Host "flutter pub get"
Write-Host "flutter run -d chrome"
Write-Host ""
Write-Host "Backup saved at: $backupRoot"
Write-Host ""
