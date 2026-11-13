$ErrorActionPreference = 'Stop'
$project = 'C:\Users\mikem\uag_traders_hub'
Set-Location -LiteralPath $project
$sourcePath = Join-Path $project 'lib\features\trading_hub\arc_raiders\screens\blueprint_grid_screen.dart'
$testPath = Join-Path $project 'test\blueprint_grid_screen_regression_test.dart'
if (!(Test-Path -LiteralPath $sourcePath) -or !(Test-Path -LiteralPath $testPath)) { throw 'PASS 33 files not found.' }
$source = [IO.File]::ReadAllText($sourcePath)
$test = [IO.File]::ReadAllText($testPath)
if (!$source.Contains('blueprint-landscape-fitted-dock')) { throw 'PASS 33 dock not installed. Refusing to modify the wrong source.' }
$menuStart = $source.IndexOf('PopupMenuButton<String>(')
$menuEnd = $source.IndexOf('const SizedBox(width: 8)', $menuStart)
if ($menuStart -lt 0 -or $menuEnd -le $menuStart) { throw 'Blueprint menu boundaries not found.' }
$menu = $source.Substring($menuStart, $menuEnd - $menuStart)
# Match the actual PASS 33 single-line PopupMenuItems, allowing whitespace or Dart formatter changes.
$items = @(
  @{ value='all'; label='All Blueprints' },
  @{ value='needed'; label='Needed Blueprints' },
  @{ value='dupes'; label='Duplicate Blueprints' },
  @{ value='camera'; label='Scan / Update Blueprints' },
  @{ value='share'; label='Share Blueprints' }
)
foreach ($item in $items) {
  $v = [regex]::Escape($item.value)
  $label = [regex]::Escape($item.label)
  $pattern = "(?s)\s*PopupMenuItem(?:<String>)?\s*\(\s*value:\s*'$v'\s*,\s*child:\s*(?:const\s+)?Text\(\s*'$label'\s*\)\s*,?\s*\)\s*,"
  $matches = [regex]::Matches($menu,$pattern)
  if ($matches.Count -ne 1) { throw "Unexpected source item [$($item.label)] count=$($matches.Count). No changes applied." }
  $menu = [regex]::Replace($menu,$pattern, "`r`n", [System.Text.RegularExpressions.RegexOptions]::Singleline)
}
# Remove the redundant divider preceding the existing first retained advanced action.
$menu = [regex]::Replace($menu, "(?s)(itemBuilder:\s*\(context\)\s*=>\s*const\s*\[)\s*PopupMenuDivider\(\)\s*,", '$1')
# Preserve switch action handlers, since they are not visible and retaining them avoids unintended behaviour changes.
# Pink labels, preserve destructive item's existing red style.
$menu = [regex]::Replace($menu, "Text\(\s*'([^']+)'\s*\)", [System.Text.RegularExpressions.MatchEvaluator]{
  param($m)
  "Text('$($m.Groups[1].Value)', style: TextStyle(color: AppTheme.neonPink))"
})
$changedSource = $source.Substring(0, $menuStart) + $menu + $source.Substring($menuEnd)
if ($changedSource -eq $source) { throw 'No source changes detected.' }
# Update the existing regression assertion that previously expected a duplicate item.
$testNeedle = "expect(find.text('Duplicate Blueprints'), findsOneWidget);"
if (!$test.Contains($testNeedle)) { throw 'Expected PASS 33 regression test is missing. No changes applied.' }
$changedTest = $test.Replace($testNeedle, "expect(find.text('Duplicate Blueprints'), findsNothing);")
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$sourceBackup = "$sourcePath.PASS34_BACKUP_$stamp"
$testBackup = "$testPath.PASS34_BACKUP_$stamp"
Copy-Item -LiteralPath $sourcePath -Destination $sourceBackup -ErrorAction Stop
Copy-Item -LiteralPath $testPath -Destination $testBackup -ErrorAction Stop
try {
  $utf8 = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($sourcePath,$changedSource,$utf8)
  [IO.File]::WriteAllText($testPath,$changedTest,$utf8)
  & dart format $sourcePath $testPath
  if ($LASTEXITCODE -ne 0) { throw 'Dart format failed' }
  & flutter analyze --no-pub --no-fatal-infos
  if ($LASTEXITCODE -ne 0) { throw 'Flutter analyzer failed' }
  & flutter test test/blueprint_grid_screen_regression_test.dart
  if ($LASTEXITCODE -ne 0) { throw 'Blueprint regression test failed' }
  & flutter test test/arc_collections_grid_ui_test.dart
  if ($LASTEXITCODE -ne 0) { throw 'Collections regression test failed' }
  Write-Host 'PASS 34 INSTALLED. Removed five redundant menu entries; remaining labels neon pink.' -ForegroundColor Green
  Write-Host "Backups: $sourceBackup ; $testBackup"
} catch {
  Copy-Item -LiteralPath $sourceBackup -Destination $sourcePath -Force
  Copy-Item -LiteralPath $testBackup -Destination $testPath -Force
  Write-Host "PASS 34 ROLLED BACK: $_" -ForegroundColor Red
  throw
}
