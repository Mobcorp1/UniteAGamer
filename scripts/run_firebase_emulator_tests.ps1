param(
  [string]$NpmPath = ''
)

$ErrorActionPreference = 'Stop'

function Write-Stage {
  param([string]$Message)
  Write-Host ""
  Write-Host "== $Message ==" -ForegroundColor Cyan
}

Write-Stage 'Validate Java 21 and Firebase CLI'
try {
  & "$PSScriptRoot\validate_release_environment.ps1" -RequireJava21
} catch {
  Write-Host ""
  Write-Host "Firebase emulator tests blocked: $($_.Exception.Message)" -ForegroundColor Red
  exit 1
}

Write-Stage 'Run Firestore Emulator Rules Tests'
$npm = $NpmPath
if ([string]::IsNullOrWhiteSpace($npm)) {
  $npmCommand = Get-Command npm -ErrorAction SilentlyContinue
  if ($null -eq $npmCommand) {
    $nodeNpm = Join-Path $env:ProgramFiles 'nodejs\npm.cmd'
    if (Test-Path $nodeNpm) {
      $npm = $nodeNpm
    } else {
      throw 'npm was not found on PATH and C:\Program Files\nodejs\npm.cmd is unavailable.'
    }
  } else {
    $npm = $npmCommand.Source
  }
}

& $npm run test:rules --prefix trading

Write-Host ""
Write-Host 'Firebase emulator rules tests completed.' -ForegroundColor Green
