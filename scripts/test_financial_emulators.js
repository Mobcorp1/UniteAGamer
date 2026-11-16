'use strict';
const { spawnSync } = require('node:child_process');
if (!/^127\.0\.0\.1:/.test(process.env.FIRESTORE_EMULATOR_HOST || '')) throw Error('Local emulator required');
for (const file of ['trading/firestore-rules.test.js', 'trading/raider-contract-rules.test.js', 'trading/financial-protection.test.js']) {
  const result = spawnSync(process.execPath, [file], { stdio: 'inherit', env: process.env });
  if (result.status !== 0) process.exit(result.status || 1);
}
