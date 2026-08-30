param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$OutputPath
)

$ErrorActionPreference = 'Stop'

$buildId = (& git -C $RepoRoot rev-parse HEAD).Trim()
$branch = (& git -C $RepoRoot branch --show-current).Trim()
$builtAt = (Get-Date).ToUniversalTime().ToString('o')

if ([string]::IsNullOrWhiteSpace($buildId)) { throw 'Unable to resolve Git build ID.' }
if ([string]::IsNullOrWhiteSpace($branch)) { $branch = 'detached' }

$env:UAG_BUILD_ID = $buildId
$env:UAG_BUILT_AT = $builtAt
$env:UAG_BRANCH = $branch

try {
  & dart run (Join-Path $RepoRoot 'tool\generate_web_version.dart') --output $OutputPath
  if ($LASTEXITCODE -ne 0) { throw 'version.json generation failed.' }
} finally {
  Remove-Item Env:UAG_BUILD_ID -ErrorAction SilentlyContinue
  Remove-Item Env:UAG_BUILT_AT -ErrorAction SilentlyContinue
  Remove-Item Env:UAG_BRANCH -ErrorAction SilentlyContinue
}

if (-not (Test-Path $OutputPath)) { throw 'version.json was not generated.' }

$version = Get-Content $OutputPath -Raw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace([string]$version.buildId)) {
  throw 'Generated version.json has no valid buildId.'
}
if ([string]$version.buildId -ne $buildId) {
  throw "Generated buildId does not match HEAD. Expected $buildId, got $($version.buildId)."
}
if ([string]::IsNullOrWhiteSpace([string]$version.builtAt)) {
  throw 'Generated version.json has no build timestamp.'
}

return [PSCustomObject]@{
  BuildId = $buildId
  Branch = $branch
  BuiltAt = $builtAt
}
