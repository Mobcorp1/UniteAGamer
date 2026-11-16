'use strict';
// Test-only Windows workaround for Firebase CLI 15.11.0 / superstatic 10:
// glob-slash converts URL paths to backslashes before minimatch sees them.
// Preload only when running the local Hosting emulator. No dependency files,
// repository Hosting configuration, or deployed services are modified.
if (process.platform === 'win32') {
  const path = require('node:path');
  const cli = path.dirname(process.argv[1]);
  const superstatic = require.resolve('superstatic', { paths: [cli] });
  const slasher = require.resolve('glob-slasher', { paths: [path.dirname(superstatic)] });
  const globSlash = require.resolve('glob-slash', { paths: [path.dirname(slasher)] });
  const original = require(globSlash);
  require.cache[globSlash].exports = value => original(value).replaceAll('\\', '/');
  console.log('Local Hosting test: normalizing Windows URL paths in memory.');
}
