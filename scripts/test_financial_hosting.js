'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const crypto = require('node:crypto');
const origin = 'http://127.0.0.1:5000';
async function main() {
  let checks = 0;
  for (const path of ['/', '/app.html', '/manifest.json', '/manifest-uag-v2.json', '/flutter_bootstrap.js', '/flutter_service_worker.js', '/firebase-messaging-sw.js', '/version.json', '/uag_update_manager.js']) {
    const response = await fetch(origin + path);
    assert.equal(response.status, 200, path);
    assert.match(response.headers.get('cache-control'), /no-cache/, path);
    checks++;
  }
  for (const path of ['/privacy', '/terms', '/support', '/subscriptions-refunds', '/app']) {
    const response = await fetch(origin + path);
    assert.equal(response.status, 200, path);
    assert.match(response.headers.get('content-type'), /text\/html/, path);
    checks++;
  }
  const files = fs.readdirSync('build/web/public-assets');
  const hashed = files.filter(x => /\.[a-f0-9]{64}\.(js|css)$/.test(x));
  assert.ok(hashed.length > 0);
  for (const file of hashed) {
    const response = await fetch(origin + '/public-assets/' + file);
    assert.equal(response.status, 200);
    assert.match(response.headers.get('cache-control'), /max-age=31536000/);
    assert.match(response.headers.get('cache-control'), /immutable/);
    const bytes = Buffer.from(await response.arrayBuffer());
    assert.ok(file.includes(crypto.createHash('sha256').update(bytes).digest('hex')));
    checks++;
  }
  for (const file of files.filter(x => /\.(js|css)$/.test(x) && !hashed.includes(x))) {
    const response = await fetch(origin + '/public-assets/' + file);
    assert.match(response.headers.get('cache-control'), /no-cache/); checks++;
  }
  const manifest = await (await fetch(origin + '/manifest-uag-v2.json')).json();
  assert.ok(manifest.start_url); assert.ok(manifest.icons.length);
  for (const icon of manifest.icons) {
    const response = await fetch(new URL(icon.src, origin + '/manifest-uag-v2.json'));
    assert.equal(response.status, 200, icon.src);
    checks++;
  }
  const asset = await fetch(origin + '/assets/AssetManifest.bin.json');
  assert.equal(asset.status, 200);
  assert.match(asset.headers.get('cache-control'), /max-age=0/);
  assert.match(asset.headers.get('cache-control'), /must-revalidate/);
  const etag = asset.headers.get('etag');
  assert.ok(etag);
  const repeat = await fetch(origin + '/assets/AssetManifest.bin.json', { headers: { 'If-None-Match': etag } });
  // Superstatic 10 directly streams exact files, bypassing its conditional
  // response handler. Verify stable validators here; CDN 304 remains a separate
  // release check rather than claiming the local emulator certifies it.
  assert.ok([200, 304].includes(repeat.status));
  if (repeat.status === 200) {
    assert.equal(repeat.headers.get('etag'), etag);
    assert.equal(await repeat.text(), await asset.text());
    console.log('CDN conditional 304: NOT VERIFIED (local superstatic returns 200).');
  }
  checks++;
  const metadata = await (await fetch(origin + '/version.json')).json();
  assert.equal(metadata.buildId, crypto.createHash('sha256').update(fs.readFileSync('build/web/main.dart.js')).digest('hex')); checks++;
  console.log('Local Hosting configuration/artifact checks: ' + checks + ' passed');
  console.log('Native PWA install, offline upgrade, push delivery and real App Check attestation require device/browser validation; this is an HTTP/artifact check.');
}
main().catch(error => { console.error(error); process.exitCode = 1; });
