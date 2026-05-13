$ErrorActionPreference = "Stop"

$projectRoot = "C:\Users\mikem\uag_traders_hub"

Write-Host ""
Write-Host "========================================"
Write-Host " UAG ARC RAIDERS HUB FULL NAMING UPDATE"
Write-Host "========================================"
Write-Host ""

if (!(Test-Path "$projectRoot\pubspec.yaml")) {
    throw "Project root not found at $projectRoot"
}

$backupRoot = Join-Path $projectRoot "_naming_update_backup"
if (Test-Path $backupRoot) {
    Remove-Item -Recurse -Force $backupRoot
}
New-Item -ItemType Directory -Force -Path $backupRoot | Out-Null

$targetName = "UAG Arc Raiders Hub"

$replacements = [ordered]@{
    "UIG Riders Hub" = $targetName
    "UIG Rider Hub" = $targetName
    "UIG Traders Hub" = $targetName
    "UIG Trader Hub" = $targetName
    "UIG Raiders Hub" = $targetName
    "UIG Raider Hub" = $targetName
    "UAG ARC Raiders Hub" = $targetName
    "UAG Raider Hub" = $targetName
    "UAG Riders Hub" = $targetName
    "UAG Rider Hub" = $targetName
    "UAG ARC Raiders Hub" = $targetName
    "UAG Trader Hub" = $targetName
    "Arc Riders Trading Hub" = $targetName
    "Arc Rider Trading Hub" = $targetName
    "Arc Raiders Trading Hub" = $targetName
    "Arc Raider Trading Hub" = $targetName
    "ARC Raiders Trading Hub" = $targetName
    "ARC Raider Trading Hub" = $targetName
    "Raiders Hub" = $targetName
}

$includeExtensions = @("*.dart","*.html","*.json","*.yaml","*.yml","*.md","*.txt")
$excludeParts = @(
    "\build\",
    "\.dart_tool\",
    "\.git\",
    "\.firebase\",
    "\functions\node_modules\",
    "\node_modules\",
    "\_patch",
    "\repair_backups",
    "\_layout_fix_backup",
    "\uag_web_layout_complete_fix",
    "\uag_web_layout_force_fix"
)

$files = Get-ChildItem -Path $projectRoot -Recurse -Include $includeExtensions -File | Where-Object {
    $full = $_.FullName
    foreach ($part in $excludeParts) {
        if ($full.Contains($part)) { return $false }
    }
    return $true
}

$changed = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $updated = $content

    foreach ($key in $replacements.Keys) {
        $updated = $updated.Replace($key, $replacements[$key])
    }

    if ($updated -ne $content) {
        $relative = $file.FullName.Substring($projectRoot.Length + 1)
        $backupFile = Join-Path $backupRoot $relative
        New-Item -ItemType Directory -Force -Path (Split-Path $backupFile) | Out-Null
        Copy-Item $file.FullName $backupFile -Force
        Set-Content -Path $file.FullName -Value $updated -Encoding UTF8
        $changed++
        Write-Host "UPDATED $relative"
    }
}

# Force key app title/browser title values even if previous wording was unusual.
$mainDart = Join-Path $projectRoot "lib\main.dart"
if (Test-Path $mainDart) {
    $text = Get-Content $mainDart -Raw
    $new = $text -replace "title:\s*'[^']*'", "title: '$targetName'"
    if ($new -ne $text) {
        Set-Content -Path $mainDart -Value $new -Encoding UTF8
        Write-Host "FORCED lib\main.dart MaterialApp title"
    }
}

$indexHtml = Join-Path $projectRoot "web\index.html"
if (Test-Path $indexHtml) {
    $text = Get-Content $indexHtml -Raw
    if ($text -match "<title>.*?</title>") {
        $new = $text -replace "<title>.*?</title>", "<title>$targetName</title>"
    } else {
        $new = $text -replace "</head>", "  <title>$targetName</title>`n</head>"
    }
    if ($new -ne $text) {
        Set-Content -Path $indexHtml -Value $new -Encoding UTF8
        Write-Host "FORCED web\index.html title"
    }
}

$manifestJson = Join-Path $projectRoot "web\manifest.json"
if (Test-Path $manifestJson) {
    $text = Get-Content $manifestJson -Raw
    $text = $text -replace '"name"\s*:\s*"[^"]*"', '"name": "UAG Arc Raiders Hub"'
    $text = $text -replace '"short_name"\s*:\s*"[^"]*"', '"short_name": "UAG Arc"'
    Set-Content -Path $manifestJson -Value $text -Encoding UTF8
    Write-Host "FORCED web\manifest.json app names"
}

$pubspec = Join-Path $projectRoot "pubspec.yaml"
if (Test-Path $pubspec) {
    $text = Get-Content $pubspec -Raw
    $text = $text -replace 'description:\s*".*?"', 'description: "UAG Arc Raiders Hub fan-made companion app."'
    Set-Content -Path $pubspec -Value $text -Encoding UTF8
    Write-Host "FORCED pubspec.yaml description"
}

Write-Host ""
Write-Host "========================================"
Write-Host " NAMING UPDATE COMPLETE"
Write-Host "========================================"
Write-Host "Target name: $targetName"
Write-Host "Changed files: $changed"
Write-Host "Backup folder: $backupRoot"
Write-Host ""
Write-Host "Now run:"
Write-Host "flutter clean"
Write-Host "flutter pub get"
Write-Host "flutter analyze"
Write-Host "flutter build web --release"
Write-Host "firebase deploy --only hosting"
Write-Host ""
