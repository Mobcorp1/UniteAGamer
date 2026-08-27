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
  [switch]$AllowPush,
  [string]$ExpectedBranch = 'beta-stabilisation',
  [switch]$AllowNonProductionBranch,
  [int]$LiveVerifyAttempts = 5,
  [int]$LiveVerifyDelaySeconds = 3
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
  if ($LASTEXITCODE -ne 0) {
    throw "$Label failed with exit code $LASTEXITCODE."
  }
}

function Get-PubspecVersionParts {
  $versionLine = (Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(.+)$' | Select-Object -First 1).Matches.Groups[1].Value.Trim()
  $parts = $versionLine -split '\+', 2
  $appVersion = if ($parts.Count -gt 0 -and $parts[0]) { $parts[0] } else { 'not-supplied' }
  $buildNumber = if ($parts.Count -gt 1 -and $parts[1]) { $parts[1] } else { '0' }
  return @{ AppVersion = $appVersion; BuildNumber = $buildNumber }
}

function Invoke-WebReleaseMetadata {
  param(
    [Parameter(Mandatory=$true)][string]$VersionPath,
    [Parameter(Mandatory=$true)][string]$ExpectedBuildId
  )

  $prepareOutput = & dart run tool/prepare_web_release.dart --output $VersionPath --expected-build-id $ExpectedBuildId 2>&1
  $prepareExit = $LASTEXITCODE
  $prepareOutput | ForEach-Object { Write-Host $_ }
  if ($prepareExit -ne 0) { throw 'Release metadata preparation failed.' }

  $validateOutput = & dart run tool/prepare_web_release.dart --validate-only $VersionPath --expected-build-id $ExpectedBuildId 2>&1
  $validateExit = $LASTEXITCODE
  $validateOutput | ForEach-Object { Write-Host $_ }
  if ($validateExit -ne 0) { throw 'Release metadata validation failed.' }

  $metadata = Get-Content $VersionPath -Raw | ConvertFrom-Json
  Write-Host "Build ID: $($metadata.buildId)" -ForegroundColor Cyan
  Write-Host "Branch: $($metadata.branch)" -ForegroundColor Cyan
  Write-Host "Built At: $($metadata.builtAt)" -ForegroundColor Cyan
  Write-Host "Version file path: $VersionPath" -ForegroundColor Cyan
  return $metadata
}

function Test-LiveVersionJson {
  param(
    [Parameter(Mandatory=$true)][string]$ExpectedBuildId
  )

  $headers = @{
    'Cache-Control' = 'no-cache'
    'Pragma' = 'no-cache'
  }

  for ($attempt = 1; $attempt -le $LiveVerifyAttempts; $attempt++) {
    $cacheBuster = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $url = "https://unite-a-gamer.web.app/version.json?ts=$cacheBuster"
    try {
      $live = Invoke-RestMethod -Uri $url -Headers $headers
      $liveBuildId = ([string]$live.buildId).Trim()
      if ($liveBuildId -eq $ExpectedBuildId) {
        Write-Host "Live version.json verified: $liveBuildId" -ForegroundColor Green
        return $live
      }
      Write-Warning "Live version mismatch on attempt $attempt. Expected $ExpectedBuildId, got $liveBuildId."
    } catch {
      Write-Warning "Live version check attempt $attempt failed: $($_.Exception.Message)"
    }

    if ($attempt -lt $LiveVerifyAttempts) {
      Start-Sleep -Seconds $LiveVerifyDelaySeconds
    }
  }

  throw "Deployment verification failed. Live version.json did not serve buildId $ExpectedBuildId."
}

Invoke-Checked 'Release environment' {
  & "$PSScriptRoot\validate_release_environment.ps1" -RequireCleanTree
}

Invoke-Checked 'Verify branch and remote head' {
  if ($ExpectedBranch -ne 'beta-stabilisation' -and -not $AllowNonProductionBranch) {
    throw "Non-production branch deployments require -AllowNonProductionBranch. ExpectedBranch was '$ExpectedBranch'."
  }

  $branch = (& git -c safe.directory="$PWD" branch --show-current).Trim()
  if ($branch -ne $ExpectedBranch) {
    throw "Expected $ExpectedBranch branch, found $branch."
  }

  & git -c safe.directory="$PWD" fetch origin
  $head = (& git -c safe.directory="$PWD" rev-parse HEAD).Trim()
  $remoteRef = "origin/$ExpectedBranch"
  $remote = (& git -c safe.directory="$PWD" rev-parse $remoteRef).Trim()
  if ($head -ne $remote) {
    throw "Local HEAD does not match $remoteRef.`nHEAD: $head`nRemote: $remote"
  }
  Write-Host "HEAD: $head"
}

Invoke-Checked 'Flutter pub get' { & flutter pub get }
Invoke-Checked 'Dart format check' { & dart format --output=none --set-exit-if-changed lib test tool }
Invoke-Checked 'Flutter analyze' { & flutter analyze }
Invoke-Checked 'Blueprint grid release guards' {
  & flutter test `
    test/arc_companion_bottom_dock_layout_test.dart `
    test/blueprint_grid_screen_regression_test.dart
}
Invoke-Checked 'Flutter tests' { & flutter test }
Invoke-Checked 'Node function syntax' { & node --check functions/index.js }

if ($RunFirebaseEmulatorTests) {
  Invoke-Checked 'Firebase emulator tests' {
    & "$PSScriptRoot\run_firebase_emulator_tests.ps1"
  }
} else {
  Write-Warning 'Firebase emulator tests skipped. Pass -RunFirebaseEmulatorTests after installing Java 21.'
}

$buildId = ''
$metadata = $null

Invoke-Checked 'Web release build' {
  $script:buildId = (& git -c safe.directory="$PWD" rev-parse HEAD).Trim()
  $builtAt = (Get-Date).ToUniversalTime().ToString('o')
  $version = Get-PubspecVersionParts
  $serviceWorkerVersion = "fcm-$($script:buildId.Substring(0, [Math]::Min(12, $script:buildId.Length)))"

  & flutter build web --release --no-wasm-dry-run `
    --dart-define="UAG_APP_VERSION=$($version.AppVersion)" `
    --dart-define="UAG_BUILD_NUMBER=$($version.BuildNumber)" `
    --dart-define="UAG_GIT_COMMIT=$script:buildId" `
    --dart-define="UAG_BUILD_TIMESTAMP=$builtAt" `
    --dart-define="UAG_HOSTING_ENVIRONMENT=production" `
    --dart-define="UAG_SERVICE_WORKER_VERSION=$serviceWorkerVersion"

  if ($LASTEXITCODE -ne 0) { throw 'Flutter web release build failed.' }

  $versionPath = Join-Path (Get-Location).Path 'build\web\version.json'
  $script:metadata = Invoke-WebReleaseMetadata -VersionPath $versionPath -ExpectedBuildId $script:buildId

  Copy-Item 'web\uag_update_manager.js' 'build\web\uag_update_manager.js' -Force
  if (Test-Path 'web\firebase-messaging-sw.js') {
    Copy-Item 'web\firebase-messaging-sw.js' 'build\web\firebase-messaging-sw.js' -Force
  }
}
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
  Invoke-Checked 'Prepare web release metadata before Hosting deploy' {
    $versionPath = Join-Path (Get-Location).Path 'build\web\version.json'
    $script:metadata = Invoke-WebReleaseMetadata -VersionPath $versionPath -ExpectedBuildId $script:buildId
  }
  Invoke-Checked 'Deploy Firebase Hosting' { & firebase deploy --only hosting }
  Invoke-Checked 'Verify Firebase Hosting build ID' {
    $live = Test-LiveVersionJson -ExpectedBuildId $script:buildId
    Write-Host "Live build ID: $($live.buildId)" -ForegroundColor Cyan
  }
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
Write-Host "Version file: build\web\version.json"
if ($metadata -ne $null) {
  Write-Host "Build ID: $($metadata.buildId)"
  Write-Host "Branch: $($metadata.branch)"
  Write-Host "Built At: $($metadata.builtAt)"
}
$finalHead = & git -c safe.directory="$PWD" rev-parse HEAD
Write-Host "Commit: $finalHead"
Write-Host 'Release candidate validation script completed.' -ForegroundColor Green
