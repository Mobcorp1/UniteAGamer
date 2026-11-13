param(
    [string]$PackageName = 'com.mobcorp.uagtradershub',
    [string]$Keystore = "$env:USERPROFILE\.android\debug.keystore",
    [string]$Alias = 'androiddebugkey',
    [string]$StorePass = 'android',
    [string]$KeyPass = 'android'
)

$ErrorActionPreference = 'Stop'
$Repo = (Get-Location).Path
$OutDir = Join-Path $Repo 'web\.well-known'
$OutFile = Join-Path $OutDir 'assetlinks.json'

if (-not (Test-Path $Keystore)) {
    throw "Android keystore not found: $Keystore"
}

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if (-not $keytool) {
    if ($env:JAVA_HOME) {
        $candidate = Join-Path $env:JAVA_HOME 'bin\keytool.exe'
        if (Test-Path $candidate) { $keytool = $candidate }
    }
}
if (-not $keytool) {
    throw 'keytool was not found. Install/use the JDK that Flutter Android builds use.'
}

$output = & $keytool -list -v -keystore $Keystore -alias $Alias `
    -storepass $StorePass -keypass $KeyPass 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "keytool could not read $Keystore"
}

$match = [regex]::Match(($output -join "`n"), 'SHA256:\s*([0-9A-F:]+)', 'IgnoreCase')
if (-not $match.Success) {
    throw 'Could not extract SHA256 certificate fingerprint.'
}

$fingerprint = $match.Groups[1].Value.ToUpperInvariant()
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$json = @"
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "$PackageName",
      "sha256_cert_fingerprints": ["$fingerprint"]
    }
  }
]
"@

Set-Content -Path $OutFile -Value $json -Encoding UTF8
Write-Host "Generated: $OutFile"
Write-Host "Package: $PackageName"
Write-Host "SHA256: $fingerprint"
Write-Host 'Deploy this file with Firebase Hosting before expecting Android autoVerify to succeed.'
