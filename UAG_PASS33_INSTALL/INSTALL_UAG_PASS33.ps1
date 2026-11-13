$ErrorActionPreference = 'Stop'
$project = 'C:\Users\mikem\uag_traders_hub'
$relative = 'lib\features\trading_hub\arc_raiders\screens\blueprint_grid_screen.dart'
$file = Join-Path $project $relative
if (-not (Test-Path -LiteralPath $file)) { throw "Missing project source: $file" }
$original = [IO.File]::ReadAllText($file)
if ($original.Contains('blueprint-landscape-fitted-dock')) { throw 'PASS 33 is already installed.' }
$source = $original
function Replace-Exactly([string]$old, [string]$new, [string]$label) {
  # Match the intended Dart code regardless of spaces, line endings or dart-format wrapping.
  $tokens = [regex]::Split($old.Trim(), '\s+') | Where-Object { $_ -ne '' }
  $pattern = ($tokens | ForEach-Object { [regex]::Escape($_) }) -join '\s+'
  $matches = [regex]::Matches($script:source, $pattern)
  if ($matches.Count -ne 1) {
    throw "Unsafe source mismatch [$label]: expected one code match, found $($matches.Count). No changes applied. The local Blueprint file differs; a source-specific patch is required."
  }
  $script:source = [regex]::new($pattern).Replace($script:source, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $new }, 1)
}
# Unreserve side-rail width, making the grid fill the restored space.
Replace-Exactly @'
            const commandRailWidth = 106.0;
            const commandRailGap = 8.0;
            final reservedSideWidth = compactNativeLandscape
                ? commandRailWidth + commandRailGap
                : 0.0;
'@ @'
            // PASS 33: the landscape controls live in the fitted bottom dock.
            const reservedSideWidth = 0.0;
'@ 'rail width'
Replace-Exactly @'
              if (compactNativeLandscape) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: availableGridHeight,
                    child: Row(
                      key: const Key('blueprint-landscape-side-layout'),
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        viewport,
                        const SizedBox(width: commandRailGap),
                        _buildGridCommandBar(
                          viewportHeight: viewportHeight,
                          gridHeight: gridHeight,
                          rowCount: rowCount,
                          enableRowJumps: enableRowJumps,
                          hasOwnedBlueprints: hasOwnedBlueprints,
                          vertical: true,
                        ),
                      ],
                    ),
                  ),
                );
              }
'@ @'
              if (compactNativeLandscape) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    key: const Key('blueprint-landscape-full-grid-layout'),
                    height: availableGridHeight,
                    child: viewport,
                  ),
                );
              }
'@ 'remove rail'
Replace-Exactly @'
                  key: const Key('blueprint-landscape-static-ad'),
                  child: widget.bannerSlot ?? const ArcBlueprintBannerSlot(),
'@ @'
                  key: const Key('blueprint-landscape-fitted-dock'),
                  child: _buildBlueprintLandscapeDock(),
'@ 'install fitted dock'
Replace-Exactly @'
                    case 'feedback':
'@ @'
                    case 'all':
                      setState(() => _selectedFilter = ArcBlueprintFilter.all);
                      return;
                    case 'needed':
                      setState(() => _selectedFilter = ArcBlueprintFilter.missing);
                      return;
                    case 'dupes':
                      setState(() => _selectedFilter = ArcBlueprintFilter.duplicates);
                      return;
                    case 'camera':
                      _openBlueprintPhotoImport();
                      return;
                    case 'share':
                      _shareBlueprintCollection();
                      return;
                    case 'in-game':
                      _setViewMode(ArcBlueprintGridViewMode.inGameFramed);
                      return;
                    case 'full-grid':
                      _setViewMode(ArcBlueprintGridViewMode.fullOverview);
                      return;
                    case 'zoom-in':
                      _zoomBlueprintGrid(0.45);
                      return;
                    case 'zoom-out':
                      _zoomBlueprintGrid(-0.45);
                      return;
                    case 'reset-view':
                      _resetBlueprintGridZoom();
                      return;
                    case 'feedback':
'@ 'wire hamburger actions'
Replace-Exactly @'
                   PopupMenuItem(value: 'search', child: Text('Search')),
'@ @'
                   PopupMenuItem(value: 'all', child: Text('All Blueprints')),
                   PopupMenuItem(value: 'needed', child: Text('Needed Blueprints')),
                   PopupMenuItem(value: 'dupes', child: Text('Duplicate Blueprints')),
                   PopupMenuItem(value: 'camera', child: Text('Scan / Update Blueprints')),
                   PopupMenuItem(value: 'share', child: Text('Share Blueprints')),
                   PopupMenuDivider(),
                   PopupMenuItem(value: 'in-game', child: Text('In-game View')),
                   PopupMenuItem(value: 'full-grid', child: Text('Full Grid View')),
                   PopupMenuItem(value: 'zoom-in', child: Text('Zoom In')),
                   PopupMenuItem(value: 'zoom-out', child: Text('Zoom Out')),
                   PopupMenuItem(value: 'reset-view', child: Text('Reset Grid View')),
                   PopupMenuDivider(),
                   PopupMenuItem(value: 'search', child: Text('Search')),
'@ 'expose hamburger actions'
$dock = @'
  /// PASS 33: landscape command dock matching the approved Stencils layout.
  /// The advertisement slot remains controlled by the existing entitlement logic.
  Widget _buildBlueprintLandscapeDock() {
    Widget action({
      required String keyName,
      required String label,
      required IconData icon,
      required VoidCallback onTap,
      bool selected = false,
      bool camera = false,
    }) {
      return Expanded(
        child: Tooltip(
          message: label,
          child: SizedBox(
            height: 42,
            child: OutlinedButton(
              key: Key(keyName),
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                backgroundColor: camera
                    ? AppTheme.neonPink
                    : selected
                        ? AppTheme.cardBackgroundAlt
                        : AppTheme.cardBackgroundDeep,
                foregroundColor: camera
                    ? AppTheme.darkBackground
                    : selected ? AppTheme.neonCyan : Colors.white70,
                side: BorderSide(
                  color: camera || selected
                      ? AppTheme.neonCyan
                      : AppTheme.neonCyan.withValues(alpha: 0.34),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 17),
                    const SizedBox(width: 4),
                    Text(label, style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(7, 2, 7, 2),
        decoration: BoxDecoration(
          color: AppTheme.darkBackground,
          border: Border(top: BorderSide(
            color: AppTheme.neonCyan.withValues(alpha: 0.25),
          )),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final adWidth = math.min(344.0,
                math.max(326.0, constraints.maxWidth * 0.43));
            return SizedBox(
              height: 74,
              child: Row(
                children: [
                  action(
                    keyName: 'blueprint-dock-all', label: 'ALL',
                    icon: Icons.apps_rounded,
                    selected: _selectedFilter == ArcBlueprintFilter.all,
                    onTap: () => setState(() => _selectedFilter = ArcBlueprintFilter.all),
                  ),
                  const SizedBox(width: 4),
                  action(
                    keyName: 'blueprint-dock-needed', label: 'NEEDED',
                    icon: Icons.help_outline_rounded,
                    selected: _selectedFilter == ArcBlueprintFilter.missing,
                    onTap: () => setState(() => _selectedFilter = ArcBlueprintFilter.missing),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    key: const Key('blueprint-dock-fitted-ad'),
                    width: adWidth,
                    height: 74,
                    child: Center(
                      child: widget.bannerSlot ?? const ArcBlueprintBannerSlot(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  action(
                    keyName: 'blueprint-dock-camera', label: 'CAMERA',
                    icon: Icons.camera_alt_outlined, camera: true,
                    onTap: _openBlueprintPhotoImport,
                  ),
                  const SizedBox(width: 4),
                  action(
                    keyName: 'blueprint-dock-share', label: 'SHARE',
                    icon: Icons.share_outlined, onTap: _shareBlueprintCollection,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

'@
Replace-Exactly @'
  Widget _buildGridCommandBar({
'@ ($dock + @'
  Widget _buildGridCommandBar({
'@) 'insert dock method'

# Keep the regression suite aligned to the approved side-rail removal.
$testRelative = 'test\blueprint_grid_screen_regression_test.dart'
$testFile = Join-Path $project $testRelative
if (-not (Test-Path -LiteralPath $testFile)) { throw "Missing regression test: $testFile" }
$testOriginal = [IO.File]::ReadAllText($testFile)
$testSource = $testOriginal
function Replace-TestPattern([string]$pattern, [string]$replacement, [string]$label) {
  $matches = [regex]::Matches($script:testSource, $pattern)
  if ($matches.Count -ne 1) {
    throw "Regression test structure differs [$label]: found $($matches.Count). No changes applied."
  }
  $script:testSource = [regex]::Replace(
    $script:testSource, $pattern,
    [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement }
  )
}
Replace-TestPattern '(?s)expect\(\s*find\.byKey\(\s*const Key\(''blueprint-grid-vertical-command-rail''\)\s*\),\s*findsOneWidget,\s*\);' @'
expect(
            find.byKey(const Key('blueprint-grid-vertical-command-rail')),
            findsNothing,
          );
'@ 'removed rail'
Replace-TestPattern '(?s)expect\(find\.byTooltip\(''Show all blueprints''\),\s*findsOneWidget\);\s*.*?expect\(find\.byTooltip\(''Zoom out''\),\s*findsOneWidget\);' @'
          expect(find.byKey(const Key('blueprint-landscape-fitted-dock')), findsOneWidget);
          expect(find.byKey(const Key('blueprint-dock-fitted-ad')), findsOneWidget);
          expect(find.byKey(const Key('blueprint-dock-all')), findsOneWidget);
          expect(find.byKey(const Key('blueprint-dock-needed')), findsOneWidget);
          expect(find.byKey(const Key('blueprint-dock-camera')), findsOneWidget);
          expect(find.byKey(const Key('blueprint-dock-share')), findsOneWidget);
'@ 'dock and menu actions'
Replace-TestPattern '(?s)expect\(multiSelectMenuItem,\s*findsOneWidget\);' @'
          expect(multiSelectMenuItem, findsOneWidget);
          expect(find.text('Duplicate Blueprints'), findsOneWidget);
          expect(find.text('In-game View'), findsOneWidget);
          expect(find.text('Full Grid View'), findsOneWidget);
          expect(find.text('Zoom In'), findsOneWidget);
          expect(find.text('Reset Grid View'), findsOneWidget);
          expect(find.text('Zoom Out'), findsOneWidget);
'@ 'hamburger menu retains every action'
# The tools panel is a lazy ListView; scroll actions into the widget tree before asserting.
Replace-TestPattern '(?s)expect\(find\.text\(''Select All Visible''\),\s*findsOneWidget\);\s*expect\(find\.text\(''Exit Selection''\),\s*findsOneWidget\);' @'
          final toolsScroll = find.descendant(
            of: find.byKey(const Key('blueprint-tools-panel')),
            matching: find.byType(Scrollable),
          ).first;
          await tester.scrollUntilVisible(
            find.text('Select All Visible'),
            90,
            scrollable: toolsScroll,
          );
          expect(find.text('Select All Visible'), findsOneWidget);
          await tester.scrollUntilVisible(
            find.text('Exit Selection'),
            90,
            scrollable: toolsScroll,
          );
          expect(find.text('Exit Selection'), findsOneWidget);
'@ 'scroll to selection actions'
# The expanded hamburger is scrollable at 360px landscape height.
Replace-TestPattern 'await tester\.tap\(multiSelectMenuItem\);' @'
          await tester.ensureVisible(multiSelectMenuItem);
          await tester.pumpAndSettle();
          await tester.tap(multiSelectMenuItem);
'@ 'scroll to multi select'

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backup = "$file.PASS33_BACKUP_$stamp"
Copy-Item -LiteralPath $file -Destination $backup
$testBackup = "$testFile.PASS33_BACKUP_$stamp"
Copy-Item -LiteralPath $testFile -Destination $testBackup
try {
  [IO.File]::WriteAllText($testFile, $testSource, (New-Object System.Text.UTF8Encoding($false)))
  [IO.File]::WriteAllText($file, $source, (New-Object System.Text.UTF8Encoding($false)))
  Push-Location $project
  try {
    dart format $relative $testRelative
    if ($LASTEXITCODE -ne 0) { throw 'dart format failed' }
    flutter analyze --no-pub --no-fatal-infos
    if ($LASTEXITCODE -ne 0) { throw 'Flutter analyzer failed' }
    flutter test test/arc_collections_grid_ui_test.dart
    if ($LASTEXITCODE -ne 0) { throw 'Collections test failed' }
    flutter test test/blueprint_grid_screen_regression_test.dart
    if ($LASTEXITCODE -ne 0) { throw 'Blueprint regression test failed' }
  } finally { Pop-Location }
  Write-Host "PASS 33 INSTALLED. Backups: $backup ; $testBackup" -ForegroundColor Green
} catch {
  Copy-Item -LiteralPath $backup -Destination $file -Force
  Copy-Item -LiteralPath $testBackup -Destination $testFile -Force
  Write-Host "PASS 33 ROLLED BACK due to validation failure: $_" -ForegroundColor Red
  throw
}
