param(
    [Parameter(Mandatory = $true)]
    [string]$AppleTeamId,
    [string]$BundleId = 'com.example.uniteAGamer'
)

$ErrorActionPreference = 'Stop'
$Repo = (Get-Location).Path
$OutDir = Join-Path $Repo 'web\.well-known'
$OutFile = Join-Path $OutDir 'apple-app-site-association'

$team = $AppleTeamId.Trim()
$bundle = $BundleId.Trim()
if ($team.Length -lt 6) { throw 'AppleTeamId looks invalid.' }
if ($bundle.Length -lt 3) { throw 'BundleId looks invalid.' }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$json = @"
{
  "applinks": {
    "details": [
      {
        "appIDs": ["$team.$bundle"],
        "components": [
          {
            "/": "/*",
            "?": {
              "creator": "?*",
              "code": "?*"
            },
            "comment": "UAG Creator Programme attribution links"
          }
        ]
      }
    ]
  }
}
"@
Set-Content -Path $OutFile -Value $json -Encoding UTF8
Write-Host "Generated: $OutFile"
Write-Host "App ID: $team.$bundle"
Write-Host 'Deploy this exact extensionless file with Firebase Hosting for iOS Universal Links verification.'
