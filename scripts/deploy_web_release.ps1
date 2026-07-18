$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

Write-Host "==> UAG web release pre-flight" -ForegroundColor Cyan

$branch = (git branch --show-current).Trim()
if ($branch -ne "beta-stabilisation") {
    throw "Expected beta-stabilisation branch, found: $branch"
}

$dirty = git status --porcelain
if ($dirty) {
    Write-Host $dirty
    throw "Working tree must be clean before a production web deployment."
}

$buildId = (git rev-parse HEAD).Trim()
$builtAt = (Get-Date).ToUniversalTime().ToString("o")

Write-Host "==> Building Flutter web release" -ForegroundColor Cyan
flutter build web --release --no-wasm-dry-run
if ($LASTEXITCODE -ne 0) {
    throw "Flutter web release build failed."
}

$versionPath = Join-Path $repo "build\web\version.json"
@{
    buildId = $buildId
    builtAt = $builtAt
    branch = $branch
} |
    ConvertTo-Json -Depth 4 |
    Set-Content -Path $versionPath -Encoding utf8

if (-not (Test-Path $versionPath)) {
    throw "version.json was not generated."
}

Write-Host "==> Selecting Firebase project" -ForegroundColor Cyan
npx firebase-tools use unite-a-gamer
if ($LASTEXITCODE -ne 0) {
    throw "Firebase project selection failed."
}

Write-Host "==> Deploying Firebase Hosting" -ForegroundColor Cyan
npx firebase-tools deploy --only hosting
if ($LASTEXITCODE -ne 0) {
    throw "Firebase Hosting deployment failed."
}

Write-Host ""
Write-Host "UAG web release deployed." -ForegroundColor Green
Write-Host "Build ID: $buildId" -ForegroundColor Cyan
Write-Host "Built at: $builtAt" -ForegroundColor Cyan
Write-Host "Live URL: https://unite-a-gamer.web.app" -ForegroundColor Cyan
