param(
  [switch]$DeployHosting,
  [switch]$DeployFirestoreRules,
  [switch]$DeployFirestoreIndexes,
  [switch]$DeployStorageRules,
  [switch]$DeployFunctions,
  [switch]$BuildAndroidRelease,
  [switch]$InstallDebugApk,
  [switch]$RunFirebaseEmulatorTests,
  [switch]$AllowCommit,
  [switch]$AllowPush
)

$ErrorActionPreference = 'Stop'

function Write-Stage {
  param([string]$Message)
  Write-Host ""
  Write-Host "== $Message ==" -ForegroundColor Cyan
}

function Invoke-Checked {
  param(
    [string]$Label,
    [scriptblock]$Command
  )
  Write-Stage $Label
  & $Command
}

Invoke-Checked 'Release environment' {
  & "$PSScriptRoot\validate_release_environment.ps1" -RequireCleanTree
}

Invoke-Checked 'Verify branch and remote head' {
  $branch = & git -c safe.directory="$PWD" branch --show-current
  if ($branch -ne 'beta-stabilisation') {
    throw "Expected beta-stabilisation branch, found $branch."
  }
  & git -c safe.directory="$PWD" fetch origin
  $head = & git -c safe.directory="$PWD" rev-parse HEAD
  $remote = & git -c safe.directory="$PWD" rev-parse origin/beta-stabilisation
  if ($head -ne $remote) {
    throw "Local HEAD does not match origin/beta-stabilisation.`nHEAD: $head`nRemote: $remote"
  }
  Write-Host "HEAD: $head"
}

Invoke-Checked 'Flutter pub get' { & flutter pub get }
Invoke-Checked 'Dart format check' { & dart format --output=none --set-exit-if-changed lib test }
Invoke-Checked 'Flutter analyze' { & flutter analyze }
Invoke-Checked 'Flutter tests' { & flutter test }
Invoke-Checked 'Node function syntax' { & node --check functions/index.js }

if ($RunFirebaseEmulatorTests) {
  Invoke-Checked 'Firebase emulator tests' {
    & "$PSScriptRoot\run_firebase_emulator_tests.ps1"
  }
} else {
  Write-Warning 'Firebase emulator tests skipped. Pass -RunFirebaseEmulatorTests after installing Java 21.'
}

Invoke-Checked 'Web release build' { & flutter build web --release --no-wasm-dry-run }
Invoke-Checked 'Android debug APK build' { & flutter build apk --debug }

if ($BuildAndroidRelease) {
  Invoke-Checked 'Android release APK build' { & flutter build apk --release }
}

Invoke-Checked 'Git diff whitespace check' { & git diff --check }

if ($InstallDebugApk) {
  Invoke-Checked 'Install debug APK on connected Android device' {
    & flutter install -d android
  }
}

if ($DeployHosting) {
  Invoke-Checked 'Deploy Firebase Hosting' { & firebase deploy --only hosting }
}

if ($DeployFirestoreRules) {
  Invoke-Checked 'Deploy Firestore rules' { & firebase deploy --only firestore:rules }
}

if ($DeployFirestoreIndexes) {
  Invoke-Checked 'Deploy Firestore indexes' { & firebase deploy --only firestore:indexes }
}

if ($DeployStorageRules) {
  Invoke-Checked 'Deploy Storage rules' { & firebase deploy --only storage }
}

if ($DeployFunctions) {
  Invoke-Checked 'Deploy Functions' { & firebase deploy --only functions }
}

if ($AllowCommit) {
  Write-Warning 'This release script intentionally does not create commits automatically. Commit manually with the requested pass message.'
}

if ($AllowPush) {
  Write-Warning 'This release script intentionally does not push automatically. Push manually after reviewing the commit.'
}

Write-Stage 'Artifacts'
Write-Host "Web output: build\web"
Write-Host "Debug APK: build\app\outputs\flutter-apk\app-debug.apk"
$finalHead = & git -c safe.directory="$PWD" rev-parse HEAD
Write-Host "Commit: $finalHead"
Write-Host 'Release candidate validation script completed.' -ForegroundColor Green
