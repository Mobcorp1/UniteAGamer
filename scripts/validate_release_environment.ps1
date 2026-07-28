param(
  [switch]$RequireJava21,
  [switch]$RequireCleanTree,
  [switch]$RequireAndroidDevice
)

$ErrorActionPreference = 'Stop'

function Write-Stage {
  param([string]$Message)
  Write-Host ""
  Write-Host "== $Message ==" -ForegroundColor Cyan
}

function Get-CommandPath {
  param([string]$Name)
  $command = Get-Command $Name -ErrorAction SilentlyContinue
  if ($null -eq $command) {
    return $null
  }
  return $command.Source
}

function Assert-Command {
  param([string]$Name)
  $path = Get-CommandPath $Name
  if ([string]::IsNullOrWhiteSpace($path)) {
    throw "$Name was not found on PATH."
  }
  Write-Host "${Name}: $path"
}

function Assert-FirebaseTooling {
  $firebase = Get-CommandPath 'firebase'
  if (-not [string]::IsNullOrWhiteSpace($firebase)) {
    Write-Host "firebase: $firebase"
    return
  }
  $npx = Get-CommandPath 'npx'
  if (-not [string]::IsNullOrWhiteSpace($npx)) {
    Write-Warning 'firebase was not found on PATH. Emulator tests can use npx firebase-tools, but deploy stages require Firebase CLI on PATH or a shell alias.'
    Write-Host "npx: $npx"
    return
  }
  throw 'firebase was not found on PATH and npx is unavailable.'
}

function Get-JavaMajorVersion {
  $javaPath = Get-CommandPath 'java'
  if ([string]::IsNullOrWhiteSpace($javaPath)) {
    return 0
  }
  $output = & cmd /d /c "java -version 2>&1" | Out-String
  Write-Host $output.Trim()
  if ($output -match 'version "([0-9]+)') {
    return [int]$Matches[1]
  }
  if ($output -match 'openjdk ([0-9]+)') {
    return [int]$Matches[1]
  }
  return 0
}

function Assert-CleanTree {
  $status = & git -c safe.directory="$PWD" status --short
  if (-not [string]::IsNullOrWhiteSpace($status)) {
    throw "Working tree is not clean. Commit, stash, or restore generated files before release validation.`n$status"
  }
  Write-Host "Working tree: clean"
}

function Test-AndroidDevice {
  $devices = & flutter devices --machine 2>$null
  if ([string]::IsNullOrWhiteSpace($devices) -or $devices -eq '[]') {
    Write-Host "Android device: none detected"
    return $false
  }
  Write-Host "Flutter devices detected."
  return $true
}

Write-Stage 'Release Environment'
Write-Host "Workspace: $PWD"

Write-Stage 'Toolchain'
Assert-Command 'git'
Assert-Command 'flutter'
Assert-Command 'dart'
Assert-Command 'node'
Assert-FirebaseTooling

Write-Stage 'Versions'
Write-Host 'Flutter: detected. Full version output is covered by explicit Flutter validation commands.'
& node --version
Write-Host 'Dart: detected. Full version output is covered by explicit Dart format validation.'
if (Get-CommandPath 'firebase') {
  & firebase --version
} else {
  Write-Warning 'Firebase CLI version not checked because firebase is not on PATH.'
}

Write-Stage 'Java'
$javaMajor = Get-JavaMajorVersion
if ($javaMajor -lt 21) {
  $message = "Java $javaMajor detected. Firebase emulator tests require Java 21 or newer. Install a Java 21 JDK and set JAVA_HOME/PATH before running emulator validation."
  if ($RequireJava21) {
    throw $message
  }
  Write-Warning $message
} else {
  Write-Host "Java: $javaMajor"
}

Write-Stage 'Git'
$branch = & git -c safe.directory="$PWD" branch --show-current
Write-Host "Branch: $branch"
if ($RequireCleanTree) {
  Assert-CleanTree
} else {
  $status = & git -c safe.directory="$PWD" status --short
  if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "Working tree: clean"
  } else {
    Write-Warning "Working tree has changes:`n$status"
  }
}

Write-Stage 'Android Devices'
$hasDevice = Test-AndroidDevice
if ($RequireAndroidDevice -and -not $hasDevice) {
  throw 'No connected Android device was detected.'
}

Write-Host ""
Write-Host 'Release environment validation completed.' -ForegroundColor Green
