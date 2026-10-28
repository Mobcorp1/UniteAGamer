param(
  [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$sourceRoot = Join-Path $RepositoryRoot 'web'
$buildRoot = Join-Path $RepositoryRoot 'build\web'
$expectedAds = 'google.com, pub-2994575443987525, DIRECT, f08c47fec0942fa0'
$primaryHost = 'https://uniteagamer.com'

function Read-RequiredText {
  param([string]$FilePath)
  if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
    throw "Required AdSense release file missing: $FilePath"
  }
  return [System.IO.File]::ReadAllText($FilePath)
}

foreach ($adsFile in @((Join-Path $sourceRoot 'ads.txt'), (Join-Path $buildRoot 'ads.txt'))) {
  $adsText = (Read-RequiredText $adsFile).Trim()
  if ($adsText -ne $expectedAds) {
    throw "Unexpected AdSense publisher record in $adsFile"
  }
}

$publicPages = @{
  'index.html' = '/'
  'about/index.html' = '/about/'
  'guides/index.html' = '/guides/'
  'guides/blueprint-tracking/index.html' = '/guides/blueprint-tracking/'
  'guides/favourite-loadout/index.html' = '/guides/favourite-loadout/'
  'guides/raid-planning/index.html' = '/guides/raid-planning/'
  'guides/safer-trading/index.html' = '/guides/safer-trading/'
}

foreach ($relativePath in $publicPages.Keys) {
  $expectedCanonical = 'rel="canonical" href="' + $primaryHost + $publicPages[$relativePath] + '"'
  foreach ($root in @($sourceRoot, $buildRoot)) {
    $pagePath = Join-Path $root $relativePath
    $page = Read-RequiredText $pagePath
    if (-not $page.Contains($expectedCanonical)) {
      throw "Incorrect canonical URL in $pagePath. Expected $expectedCanonical"
    }
    if ($page.Contains('https://unite-a-gamer.web.app/')) {
      throw "Secondary domain remains in public page metadata: $pagePath"
    }
  }
}

foreach ($root in @($sourceRoot, $buildRoot)) {
  $homePath = Join-Path $root 'index.html'
  $home = Read-RequiredText $homePath
  if (-not $home.Contains('<meta name="google-adsense-account" content="ca-pub-2994575443987525">')) {
    throw "AdSense ownership meta tag missing from $homePath"
  }

  $robotsPath = Join-Path $root 'robots.txt'
  $robots = Read-RequiredText $robotsPath
  if (-not $robots.Contains('Sitemap: https://uniteagamer.com/sitemap.xml')) {
    throw "Incorrect sitemap reference in $robotsPath"
  }

  $sitemapPath = Join-Path $root 'sitemap.xml'
  $sitemap = Read-RequiredText $sitemapPath
  if (-not $sitemap.Contains('<loc>https://uniteagamer.com/</loc>')) {
    throw "Primary domain is missing from $sitemapPath"
  }
  if ($sitemap.Contains('unite-a-gamer.web.app')) {
    throw "Secondary domain is still referenced in $sitemapPath"
  }
}

Write-Host 'UAG AdSense publisher, canonical URLs and release artifacts verified.' -ForegroundColor Green
exit 0
