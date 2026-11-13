param(
  [Parameter(Mandatory=$true)]
  [string]$Sha256Fingerprint
)

$ErrorActionPreference = 'Stop'

$normalised = $Sha256Fingerprint.Trim().ToUpperInvariant()
if ($normalised -notmatch '^([0-9A-F]{2}:){31}[0-9A-F]{2}$') {
  throw 'Fingerprint must contain exactly 32 colon-separated SHA-256 hex bytes, as shown by Google Play Console App Signing.'
}

$path = Join-Path (Get-Location).Path 'web\.well-known\assetlinks.json'
if (-not (Test-Path -LiteralPath $path)) {
  throw "assetlinks.json was not found: $path"
}

$content = @(Get-Content -LiteralPath $path -Raw | ConvertFrom-Json)
if ($content.Count -ne 1) {
  throw 'Expected exactly one Android Digital Asset Links target.'
}

$entry = $content[0]
if ($entry.target.namespace -ne 'android_app' -or $entry.target.package_name -ne 'com.mobcorp.uagtradershub') {
  throw 'assetlinks.json does not target com.mobcorp.uagtradershub.'
}

$entry.target.sha256_cert_fingerprints = @($normalised)
$json = $content | ConvertTo-Json -Depth 8
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($path, $json + [Environment]::NewLine, $utf8NoBom)

Write-Host "Updated: $path" -ForegroundColor Green
Write-Host 'Fingerprint source must be Google Play Console > Setup > App integrity > App signing key certificate.' -ForegroundColor Cyan
Write-Host 'No Firebase deploy was performed.' -ForegroundColor Yellow
