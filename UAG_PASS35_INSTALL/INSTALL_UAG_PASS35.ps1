$ErrorActionPreference = 'Stop'
Set-Location 'C:\Users\mikem\uag_traders_hub'
$sourcePath = Join-Path (Get-Location) 'lib\features\trading_hub\arc_raiders\screens\blueprint_grid_screen.dart'
$testPath = Join-Path (Get-Location) 'test\blueprint_grid_screen_regression_test.dart'
$source = [IO.File]::ReadAllText($sourcePath)
$test = [IO.File]::ReadAllText($testPath)
if (-not $source.Contains('blueprint-landscape-fitted-dock')) { throw 'The expected PASS 33 source is not installed. No files changed.' }
$start = $source.IndexOf('PopupMenuButton<String>(')
$end = $source.IndexOf('const SizedBox(width: 8)', $start)
if ($start -lt 0 -or $end -le $start) { throw 'Cannot locate the Blueprint hamburger. No files changed.' }
$menu = $source.Substring($start, $end-$start)

function Remove-MenuItem([string]$text,[string]$label) {
    $needle = "'$label'"
    $where = $text.IndexOf($needle)
    if ($where -lt 0 -or $text.IndexOf($needle, $where+1) -ge 0) { throw "Menu label '$label' not found exactly once. No files changed." }
    $itemStart = $text.LastIndexOf('PopupMenuItem', $where)
    if ($itemStart -lt 0) { throw "Missing PopupMenuItem for '$label'." }
    $nextItem = $text.IndexOf('PopupMenuItem', $itemStart+1)
    if ($nextItem -ge 0 -and $nextItem -lt $where) { throw "Ambiguous menu item for '$label'." }
    $open = $text.IndexOf('(', $itemStart)
    $depth = 0; $quote = [char]0; $escaped = $false; $close = -1
    for ($i=$open; $i -lt $text.Length; $i++) {
        $c = $text[$i]
        if ($quote -ne [char]0) {
            if ($escaped) { $escaped = $false; continue }
            if ($c -eq '\') { $escaped=$true; continue }
            if ($c -eq $quote) { $quote=[char]0 }
            continue
        }
        if ($c -eq "'" -or $c -eq '"') { $quote=$c; continue }
        if ($c -eq '(') { $depth++ }
        if ($c -eq ')') { $depth--; if ($depth -eq 0) { $close=$i; break } }
    }
    if ($close -lt $where) { throw "Could not identify complete item '$label'." }
    $removeStart = $itemStart
    $prefix = $text.Substring(0,$itemStart)
    if ($prefix.EndsWith('const ')) { $removeStart -= 6 }
    $removeEnd=$close+1
    while ($removeEnd -lt $text.Length -and [char]::IsWhiteSpace($text[$removeEnd]) -and $text[$removeEnd] -ne "`n") { $removeEnd++ }
    if ($removeEnd -ge $text.Length -or $text[$removeEnd] -ne ',') { throw "Item '$label' has no trailing comma." }
    $removeEnd++
    return $text.Remove($removeStart,$removeEnd-$removeStart)
}
$menu = Remove-MenuItem $menu 'In-game View'
$menu = Remove-MenuItem $menu 'Full Grid View'
foreach ($label in @('In-game View','Full Grid View')) {
  if ($menu.Contains("'$label'")) { throw "Removal check failed: $label" }
}
$updated = $source.Substring(0,$start) + $menu + $source.Substring($end)
foreach ($value in @('in-game','full-grid')) {
  $pattern = "(?ms)^\s*case\s+'$value'\s*:\s*\r?\n.*?^\s*return\s*;\s*\r?\n"
  if ([regex]::Matches($updated,$pattern).Count -eq 1) { $updated = [regex]::Replace($updated,$pattern,"`r`n") }
}
foreach ($label in @('In-game View','Full Grid View')) {
  $test = $test.Replace("expect(find.text('$label'), findsOneWidget);", "expect(find.text('$label'), findsNothing);")
}
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$backupSource="$sourcePath.PASS35_SAFE_$stamp"
$backupTest="$testPath.PASS35_SAFE_$stamp"
Copy-Item -LiteralPath $sourcePath -Destination $backupSource
Copy-Item -LiteralPath $testPath -Destination $backupTest
try {
  $utf8=New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($sourcePath,$updated,$utf8)
  [IO.File]::WriteAllText($testPath,$test,$utf8)
  & dart format $sourcePath $testPath
  if ($LASTEXITCODE -ne 0) { throw 'Dart format failed' }
  & flutter analyze --no-pub --no-fatal-infos
  if ($LASTEXITCODE -ne 0) { throw 'Flutter analyzer failed' }
  & flutter test test/blueprint_grid_screen_regression_test.dart
  if ($LASTEXITCODE -ne 0) { throw 'Blueprint regression tests failed' }
} catch {
  Copy-Item -LiteralPath $backupSource -Destination $sourcePath -Force
  Copy-Item -LiteralPath $backupTest -Destination $testPath -Force
  throw "PASS 35 rolled back: $_"
}
Write-Host 'PASS 35 source updated and tests passed. Building and installing on Sony.' -ForegroundColor Cyan
$device='adb-HQ645V13C0-BmghuJ._adb-tls-connect._tcp'
& flutter run -d $device
if ($LASTEXITCODE -ne 0) { throw 'Sony launch failed; updated source remains installed locally.' }
