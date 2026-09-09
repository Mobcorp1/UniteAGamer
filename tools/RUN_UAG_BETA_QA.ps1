param(
  [switch]$SkipAnalyze,
  [switch]$SkipApk
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$flutter = 'C:\src\flutter\bin\flutter.bat'
$tests = @(
  'test/uag_beta_readiness_static_contract_test.dart',
  'test/uag_beta_readiness_ui_smoke_test.dart',
  'test/arc_text_sanitizer_test.dart',
  'test/favourite_loadout_responsive_contract_test.dart',
  'test/arc_companion_bottom_dock_layout_test.dart',
  'test/arc_compact_navigation_catalog_test.dart',
  'test/arc_loadout_asset_integrity_test.dart',
  'test/uag_profile_locker_functional_closure_test.dart',
  'test/arc_match_compatibility_engine_test.dart',
  'test/arc_trade_intelligence_engine_test.dart',
  'test/arc_trade_objective_network_test.dart'
)

Write-Host 'Running UAG beta readiness targeted tests...'
& $flutter test --no-pub @tests

if (-not $SkipAnalyze) {
  Write-Host 'Running flutter analyze...'
  & $flutter analyze
}

if (-not $SkipApk) {
  Write-Host 'Building Android debug APK...'
  & $flutter build apk --debug
}
