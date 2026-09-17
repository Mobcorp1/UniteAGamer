param(
  [switch]$SkipTests,
  [switch]$AllowDirtyTree
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

Write-Host 'UAG PLAY INTERNAL/CLOSED TEST BUILD' -ForegroundColor Cyan
Write-Host 'This script builds a signed Android App Bundle only. It does not upload, publish, push, or deploy.'

if ($AllowDirtyTree) {
  & "$PSScriptRoot\validate_release_environment.ps1" -RequireAndroidReleaseSigning
} else {
  & "$PSScriptRoot\validate_release_environment.ps1" -RequireCleanTree -RequireAndroidReleaseSigning
}
if ($LASTEXITCODE -ne 0) {
  throw "Release environment validation failed with exit code $LASTEXITCODE."
}

Invoke-Checked 'Flutter pub get' { & flutter pub get }
Invoke-Checked 'Dart format check' { & dart format --output=none --set-exit-if-changed lib test tool }
Invoke-Checked 'Flutter analyze' { & flutter analyze }

if (-not $SkipTests) {
  Invoke-Checked 'Flutter tests' { & flutter test }
} else {
  Write-Warning 'Full Flutter tests were skipped by explicit request.'
}

Invoke-Checked 'Build signed Play App Bundle' { & flutter build appbundle --release }

$aab = Join-Path (Get-Location).Path 'build\app\outputs\bundle\release\app-release.aab'
if (-not (Test-Path -LiteralPath $aab)) {
  throw "Expected App Bundle was not produced: $aab"
}

$versionLine = (Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(.+)$' | Select-Object -First 1).Matches.Groups[1].Value.Trim()
$head = (& git -c safe.directory="$PWD" rev-parse --short HEAD).Trim()
$hash = (Get-FileHash -LiteralPath $aab -Algorithm SHA256).Hash

Write-Stage 'Play Test Artifact'
Write-Host 'Package: com.mobcorp.uagtradershub' -ForegroundColor Green
Write-Host "Version: $versionLine"
Write-Host "HEAD: $head"
Write-Host "AAB: $aab" -ForegroundColor Green
Write-Host "SHA-256: $hash"
Write-Host ''
Write-Host 'No Google Play upload was performed.' -ForegroundColor Yellow
Write-Host 'No GitHub push was performed.' -ForegroundColor Yellow
Write-Host 'No Firebase deploy was performed.' -ForegroundColor Yellow
