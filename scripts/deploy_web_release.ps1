param(
    [string]$ExpectedBranch = "beta-stabilisation",
    [switch]$AllowNonProductionBranch,
    [int]$LiveVerifyAttempts = 5,
    [int]$LiveVerifyDelaySeconds = 3
)

$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

function Write-Stage {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Assert-ExpectedBranch {
    $branch = (git branch --show-current).Trim()
    if ($ExpectedBranch -ne "beta-stabilisation" -and -not $AllowNonProductionBranch) {
        throw "Non-production branch deployments require -AllowNonProductionBranch. ExpectedBranch was '$ExpectedBranch'."
    }
    if ($branch -ne $ExpectedBranch) {
        throw "Expected $ExpectedBranch branch, found: $branch"
    }
    return $branch
}

function Get-PubspecVersionParts {
    $versionLine = (Select-String -Path "pubspec.yaml" -Pattern '^version:\s*(.+)$' | Select-Object -First 1).Matches.Groups[1].Value.Trim()
    $parts = $versionLine -split '\+', 2
    $appVersion = if ($parts.Count -gt 0 -and $parts[0]) { $parts[0] } else { "not-supplied" }
    $buildNumber = if ($parts.Count -gt 1 -and $parts[1]) { $parts[1] } else { "0" }
    return @{ AppVersion = $appVersion; BuildNumber = $buildNumber }
}

function Invoke-WebReleaseMetadata {
    param(
        [Parameter(Mandatory=$true)][string]$VersionPath,
        [Parameter(Mandatory=$true)][string]$ExpectedBuildId
    )

    $prepareOutput = & dart run tool/prepare_web_release.dart --output $VersionPath --expected-build-id $ExpectedBuildId 2>&1
    $prepareExit = $LASTEXITCODE
    $prepareOutput | ForEach-Object { Write-Host $_ }
    if ($prepareExit -ne 0) { throw "Release metadata preparation failed." }

    $validateOutput = & dart run tool/prepare_web_release.dart --validate-only $VersionPath --expected-build-id $ExpectedBuildId 2>&1
    $validateExit = $LASTEXITCODE
    $validateOutput | ForEach-Object { Write-Host $_ }
    if ($validateExit -ne 0) { throw "Release metadata validation failed." }

    $metadata = Get-Content $VersionPath -Raw | ConvertFrom-Json
    Write-Host "Build ID: $($metadata.buildId)" -ForegroundColor Cyan
    Write-Host "Branch: $($metadata.branch)" -ForegroundColor Cyan
    Write-Host "Built At: $($metadata.builtAt)" -ForegroundColor Cyan
    Write-Host "Version file path: $VersionPath" -ForegroundColor Cyan
    return $metadata
}

function Test-LiveVersionJson {
    param(
        [Parameter(Mandatory=$true)][string]$ExpectedBuildId
    )

    $headers = @{
        "Cache-Control" = "no-cache"
        "Pragma" = "no-cache"
    }

    for ($attempt = 1; $attempt -le $LiveVerifyAttempts; $attempt++) {
        $cacheBuster = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $url = "https://unite-a-gamer.web.app/version.json?ts=$cacheBuster"
        try {
            $live = Invoke-RestMethod -Uri $url -Headers $headers
            $liveBuildId = ([string]$live.buildId).Trim()
            if ($liveBuildId -eq $ExpectedBuildId) {
                Write-Host "Live version.json verified: $liveBuildId" -ForegroundColor Green
                return $live
            }
            Write-Warning "Live version mismatch on attempt $attempt. Expected $ExpectedBuildId, got $liveBuildId."
        } catch {
            Write-Warning "Live version check attempt $attempt failed: $($_.Exception.Message)"
        }

        if ($attempt -lt $LiveVerifyAttempts) {
            Start-Sleep -Seconds $LiveVerifyDelaySeconds
        }
    }

    throw "Deployment verification failed. Live version.json did not serve buildId $ExpectedBuildId."
}

Write-Stage "UAG web release pre-flight"
$branch = Assert-ExpectedBranch

$dirty = git status --porcelain
if ($dirty) {
    Write-Host $dirty
    throw "Working tree must be clean before a production web deployment."
}

$buildId = (git rev-parse HEAD).Trim()
$builtAt = (Get-Date).ToUniversalTime().ToString("o")
$version = Get-PubspecVersionParts
$serviceWorkerVersion = "fcm-$($buildId.Substring(0, [Math]::Min(12, $buildId.Length)))"

Write-Stage "Building Flutter web release"
flutter build web --release --no-wasm-dry-run `
  --dart-define="UAG_APP_VERSION=$($version.AppVersion)" `
  --dart-define="UAG_BUILD_NUMBER=$($version.BuildNumber)" `
  --dart-define="UAG_GIT_COMMIT=$buildId" `
  --dart-define="UAG_BUILD_TIMESTAMP=$builtAt" `
  --dart-define="UAG_HOSTING_ENVIRONMENT=production" `
  --dart-define="UAG_SERVICE_WORKER_VERSION=$serviceWorkerVersion"
if ($LASTEXITCODE -ne 0) {
    throw "Flutter web release build failed."
}

$versionPath = Join-Path $repo "build\web\version.json"
$metadata = Invoke-WebReleaseMetadata -VersionPath $versionPath -ExpectedBuildId $buildId

Copy-Item "web\uag_update_manager.js" "build\web\uag_update_manager.js" -Force
if (Test-Path "web\firebase-messaging-sw.js") {
    Copy-Item "web\firebase-messaging-sw.js" "build\web\firebase-messaging-sw.js" -Force
}

Write-Stage "Selecting Firebase project"
npx firebase-tools use unite-a-gamer
if ($LASTEXITCODE -ne 0) { throw "Firebase project selection failed." }

Write-Stage "Deploying Firebase Hosting"
npx firebase-tools deploy --only hosting
if ($LASTEXITCODE -ne 0) { throw "Firebase Hosting deployment failed." }

Write-Stage "Verifying live deployment"
$live = Test-LiveVersionJson -ExpectedBuildId $buildId

Write-Host ""
Write-Host "UAG web release deployed." -ForegroundColor Green
Write-Host "Build ID: $buildId" -ForegroundColor Cyan
Write-Host "Branch: $branch" -ForegroundColor Cyan
Write-Host "Built at: $($metadata.builtAt)" -ForegroundColor Cyan
Write-Host "Live build ID: $($live.buildId)" -ForegroundColor Cyan
Write-Host "Live URL: https://unite-a-gamer.web.app" -ForegroundColor Cyan
