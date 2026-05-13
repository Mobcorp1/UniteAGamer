Write-Host ""
Write-Host "========================================"
Write-Host " UAG DELETE REPAIR BACKUPS CLEANUP"
Write-Host "========================================"
Write-Host ""

$ErrorActionPreference = "Stop"
$root = Get-Location

$folders = @(
  "repair_backups",
  "_patch_backups",
  "_patch_backups_safe",
  "_patch_recovery_backups",
  "_patch_recovery_backups_safe"
)

foreach ($folder in $folders) {
  $path = Join-Path $root $folder
  if (Test-Path $path) {
    Remove-Item -Recurse -Force $path
    Write-Host "REMOVED $folder"
  } else {
    Write-Host "OK no $folder"
  }
}

$analysisPath = Join-Path $root "analysis_options.yaml"
if (Test-Path $analysisPath) {
  $text = Get-Content $analysisPath -Raw
  if ($text -notmatch "repair_backups") {
    if ($text -notmatch "analyzer:") {
      $text += "`n`nanalyzer:`n  exclude:`n    - '**/repair_backups/**'`n    - '**/_patch_backups/**'`n    - '**/_patch_backups_safe/**'`n    - '**/_patch_recovery_backups/**'`n    - '**/_patch_recovery_backups_safe/**'`n"
    } elseif ($text -notmatch "exclude:") {
      $text += "`n  exclude:`n    - '**/repair_backups/**'`n    - '**/_patch_backups/**'`n    - '**/_patch_backups_safe/**'`n    - '**/_patch_recovery_backups/**'`n    - '**/_patch_recovery_backups_safe/**'`n"
    } else {
      $text += "`n    - '**/repair_backups/**'`n    - '**/_patch_backups/**'`n    - '**/_patch_backups_safe/**'`n    - '**/_patch_recovery_backups/**'`n    - '**/_patch_recovery_backups_safe/**'`n"
    }
    Set-Content -Path $analysisPath -Value $text -Encoding UTF8
    Write-Host "PATCHED analysis_options.yaml backup excludes"
  } else {
    Write-Host "OK analysis_options.yaml already excludes repair_backups"
  }
}

Write-Host ""
Write-Host "DONE. Now run:"
Write-Host "flutter analyze"
Write-Host "flutter run -d chrome"
Write-Host ""
