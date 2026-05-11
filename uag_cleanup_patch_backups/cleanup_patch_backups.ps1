Write-Host ""
Write-Host "========================================"
Write-Host " UAG CLEAN PATCH BACKUP FOLDERS"
Write-Host "========================================"
Write-Host ""

$ErrorActionPreference = "Stop"
$root = Get-Location

$backupFolders = @(
  "_patch_backups",
  "_patch_recovery_backups",
  "_patch_backups_old",
  "_patch_recovery_backups_old"
)

foreach ($folder in $backupFolders) {
  $path = Join-Path $root $folder
  if (Test-Path $path) {
    Write-Host "Removing $folder ..."
    Remove-Item -LiteralPath $path -Recurse -Force
  } else {
    Write-Host "Not found: $folder"
  }
}

Write-Host ""
Write-Host "Backup cleanup complete."
Write-Host "Now run: flutter analyze"
Write-Host ""
