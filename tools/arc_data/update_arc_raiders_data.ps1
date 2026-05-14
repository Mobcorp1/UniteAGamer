$ErrorActionPreference = "Stop"

$repoOwner = "RaidTheory"
$repoName = "arcraiders-data"
$branch = "main"
$outputRoot = Join-Path $PSScriptRoot "source"
$itemOutput = Join-Path $outputRoot "raidtheory_items"

New-Item -ItemType Directory -Force -Path $itemOutput | Out-Null

Write-Host "Fetching ARC Raiders item file list from GitHub..." -ForegroundColor Cyan
$apiUrl = "https://api.github.com/repos/$repoOwner/$repoName/contents/items?ref=$branch"
$items = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "UAG-Traders-Hub" }

$jsonItems = $items | Where-Object { $_.name -like "*.json" }
Write-Host "Found $($jsonItems.Count) item JSON files." -ForegroundColor Cyan

foreach ($item in $jsonItems) {
    $targetPath = Join-Path $itemOutput $item.name
    Invoke-WebRequest -Uri $item.download_url -OutFile $targetPath -Headers @{ "User-Agent" = "UAG-Traders-Hub" }
}

$licenseUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/$branch/LICENSE"
$readmeUrl = "https://raw.githubusercontent.com/$repoOwner/$repoName/$branch/README.md"
Invoke-WebRequest -Uri $licenseUrl -OutFile (Join-Path $outputRoot "RAIDTHEORY_LICENSE") -Headers @{ "User-Agent" = "UAG-Traders-Hub" }
Invoke-WebRequest -Uri $readmeUrl -OutFile (Join-Path $outputRoot "RAIDTHEORY_README.md") -Headers @{ "User-Agent" = "UAG-Traders-Hub" }

Write-Host "Done. Review downloaded data in: $itemOutput" -ForegroundColor Green
Write-Host "Do not commit images. Preserve RaidTheory MIT license attribution if converted into app data." -ForegroundColor Yellow
