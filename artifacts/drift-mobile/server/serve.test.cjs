const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const net = require('node:net');
const { spawn } = require('node:child_process');
const { once } = require('node:events');

test('published mobile preview serves parseable Expo Go manifests', async () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'drift-manifest-'));
  let child;
  try {
    fs.mkdirSync(path.join(root, 'server/templates'), { recursive: true });
    fs.mkdirSync(path.join(root, 'static-build/ios'), { recursive: true });
    fs.copyFileSync(path.join(__dirname, 'serve.js'), path.join(root, 'server/serve.js'));
    fs.copyFileSync(path.join(__dirname, 'templates/landing-page.html'), path.join(root, 'server/templates/landing-page.html'));
    fs.writeFileSync(path.join(root, 'app.json'), JSON.stringify({ expo: { name: 'Drift' } }));
    const manifest = {
      id: '00000000-0000-4000-8000-000000000001',
      createdAt: '2026-10-11T00:00:00.000Z',
      runtimeVersion: 'exposdk:57.0.0',
      launchAsset: { key: 'bundle', contentType: 'application/javascript', url: 'https://example.com/bundle.js' },
      assets: [], metadata: {},
      extra: { expoClient: { name: 'Drift — Sleep', sdkVersion: '57.0.0' } },
    };
    fs.writeFileSync(path.join(root, 'static-build/ios/manifest.json'), JSON.stringify(manifest));
    const probe = net.createServer();
    probe.listen(0, '127.0.0.1');
    await once(probe, 'listening');
    const port = probe.address().port;
    await new Promise(resolve => probe.close(resolve));
    child = spawn(process.execPath, [path.join(root, 'server/serve.js')], {
      env: { ...process.env, PORT: String(port), BASE_PATH: '/drift-mobile/' },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    await new Promise((resolve, reject) => {
      const timeout = setTimeout(() => reject(new Error('Test server did not start')), 10000);
      child.stdout.on('data', data => {
        if (String(data).includes('Serving static Expo build')) { clearTimeout(timeout); resolve(); }
      });
      child.once('error', error => { clearTimeout(timeout); reject(error); });
    });
    const url = `http://127.0.0.1:${port}/drift-mobile/`;
    const plain = await fetch(url, { headers: { 'expo-platform': 'ios', accept: 'application/expo+json' } });
    assert.equal(plain.status, 200);
    assert.equal(plain.headers.get('expo-protocol-version'), '0');
    assert.equal(plain.headers.get('content-type'), 'application/expo+json');
    assert.deepEqual(await plain.json(), manifest);

    const multipart = await fetch(url, {
      headers: { 'expo-platform': 'ios', 'expo-protocol-version': '1', accept: 'multipart/mixed,application/expo+json,application/json' },
    });
    assert.equal(multipart.status, 200);
    assert.equal(multipart.headers.get('expo-protocol-version'), '0');
    const contentType = multipart.headers.get('content-type');
    assert.match(contentType, /^multipart\/mixed; boundary=/);
    const body = await multipart.arrayBuffer();
    assert.equal(Number(multipart.headers.get('content-length')), body.byteLength);
    const parts = await new Response(body, {
      headers: { 'content-type': contentType.replace('multipart/mixed', 'multipart/form-data') },
    }).formData();
    assert.deepEqual(JSON.parse(await parts.get('manifest').text()), manifest);

    const query = await fetch(`${url}manifest/?platform=ios`);
    assert.deepEqual(await query.json(), manifest);
    const missing = await fetch(url, { headers: { 'expo-platform': 'android' } });
    assert.equal(missing.status, 404);
    const landing = await fetch(url);
    assert.match(landing.headers.get('content-type'), /text\/html/);
    assert.match(await landing.text(), /exps:.*\/drift-mobile/);
  } finally {
    if (child && child.exitCode === null) {
      const exited = once(child, 'exit');
      child.kill();
      await exited;
    }
    fs.rmSync(root, { recursive: true, force: true });
  }
});
