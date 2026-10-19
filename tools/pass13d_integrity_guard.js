'use strict';
const fs = require('node:fs');
const assert = require('node:assert/strict');
const {execFileSync} = require('node:child_process');
const main = fs.readFileSync('lib/main.dart','utf8');
const grid = fs.readFileSync('lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart','utf8');
const overview = fs.readFileSync('lib/features/trading_hub/arc_raiders/screens/arc_blueprint_collection_overview_screen.dart','utf8');
const service = fs.readFileSync('lib/features/trading_hub/arc_raiders/services/uag_android_responsiveness_guard.dart','utf8');
assert.match(main,/UagAndroidResponsivenessGuard\.instance\.install\(\)/);
assert.match(grid,/UagAndroidResponsivenessGuard\.instance\.enterSurface\('BlueprintGridScreen'\)/);
assert.match(grid,/UagAndroidResponsivenessGuard\.instance\.exitSurface\('BlueprintGridScreen'\)/);
assert.match(overview,/enterSurface\('BlueprintCollectionOverview'\)/);
assert.match(service,/void didHaveMemoryPressure\(\)/);
assert.match(service,/addTimingsCallback/);
assert.match(service,/retainedImageCacheLimitBytes/);
// Read-only authoritative invariant: this pass MUST NOT modify these locked files.
for (const path of [
 'lib/features/trading_hub/arc_raiders/widgets/blueprint_tile.dart',
 'lib/features/trading_hub/arc_raiders/models/arc_blueprint_state.dart',
 'lib/features/trading_hub/arc_raiders/repositories/arc_blueprint_repository.dart',
]) {
 const delta = execFileSync('git',['diff','--',path],{encoding:'utf8'}).trim();
 assert.equal(delta,'',`PASS13D must not modify ${path}`);
}
// PASS 13D is allowed to insert ONLY one import and two lifecycle markers
// into the 3,000+ line locked Blueprint grid screen. No grid body edits.
const delta = execFileSync('git', ['diff', '--unified=0', '--',
 'lib/features/trading_hub/arc_raiders/screens/blueprint_grid_screen.dart'],
 {encoding:'utf8'});
const additions = delta.split(/\r?\n/).filter(s=>s.startsWith('+')&&!s.startsWith('+++'));
const removals = delta.split(/\r?\n/).filter(s=>s.startsWith('-')&&!s.startsWith('---'));
assert.equal(removals.length, 0, 'Protected grid file has removed/changed lines');
const allowed = new Set([
 "+import 'package:uag_arc_raiders_hub/features/trading_hub/arc_raiders/services/uag_android_responsiveness_guard.dart';",
 "+    UagAndroidResponsivenessGuard.instance.enterSurface('BlueprintGridScreen');",
 "+    UagAndroidResponsivenessGuard.instance.exitSurface('BlueprintGridScreen');",
]);
assert.equal(additions.length,3,'Expected exactly 3 grid lifecycle/import additions');
for (const line of additions) assert(allowed.has(line), `Unexpected Blueprint screen change ${line}`);
console.log('PASS13D protected BlueprintTile, ownership, and entire grid body contract PASS');
