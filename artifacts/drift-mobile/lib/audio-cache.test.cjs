const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');

const bundle = fs.readFileSync(process.argv[2], 'utf8');
function setup({ cached = false, contentType = 'audio/wav', status = 200 } = {}) {
  const files = new Map();
  let downloads = 0;
  const module = { exports: {} };
  const nativeFs = {
    documentDirectory: 'file:///documents/',
    getInfoAsync: async uri => ({ exists: files.has(uri), size: files.get(uri) ?? 0 }),
    makeDirectoryAsync: async () => {},
    deleteAsync: async uri => { files.delete(uri); },
    moveAsync: async ({ from, to }) => { files.set(to, files.get(from)); files.delete(from); },
    createDownloadResumable: (url, tmp, options, progress) => {
      assert.match(url, /loop-v2-.*\.wav$/);
      downloads++;
      return {
        downloadAsync: async () => {
          files.set(tmp, 1600000);
          progress({ totalBytesWritten: 1600000, totalBytesExpectedToWrite: 1600000 });
          return { status, headers: { 'Content-Type': contentType } };
        },
      };
    },
  };
  vm.runInNewContext(bundle, {
    module, exports: module.exports,
    require: name => {
      assert.equal(name, 'expo-file-system/legacy');
      return nativeFs;
    },
    process: { env: { EXPO_PUBLIC_DOMAIN: 'audio.example.test' } },
  });
  const cache = module.exports;
  if (cached) files.set(cache.localAudioPath('gentle-rain'), 1600000);
  return { cache, files, downloads: () => downloads };
}

test('concurrent Play and Save All share a single complete lossless download', async () => {
  const { cache, files, downloads } = setup();
  const old = 'file:///documents/drift-audio/native-gentle-rain.mp3';
  files.set(old, 400000);
  const first = cache.ensureLoopDownloaded('gentle-rain', () => {});
  const second = cache.ensureLoopDownloaded('gentle-rain', () => {});
  assert.equal(first, second);
  const saved = await first;
  assert.equal(downloads(), 1);
  assert.equal(files.get(saved), 1600000);
  assert.equal(files.has(`${saved}.part`), false);
  assert.equal(files.has(old), false);
  // Subsequent playback is local, including when no network is available.
  assert.equal(await cache.ensureLoopDownloaded('gentle-rain', () => {}), saved);
  assert.equal(downloads(), 1);
});

test('an existing WAV never downloads again', async () => {
  const { cache, downloads } = setup({ cached: true });
  await cache.ensureLoopDownloaded('gentle-rain', () => {});
  assert.equal(downloads(), 0);
});

test('HTML/error responses are not saved as audio and preserve the old download', async () => {
  for (const options of [{ contentType: 'text/html' }, { status: 503 }]) {
    const { cache, files } = setup(options);
    const old = 'file:///documents/drift-audio/native-gentle-rain.mp3';
    files.set(old, 400000);
    await assert.rejects(cache.ensureLoopDownloaded('gentle-rain', () => {}));
    assert.equal(files.has(cache.localAudioPath('gentle-rain')), false);
    assert.equal(files.has(`${cache.localAudioPath('gentle-rain')}.part`), false);
    assert.equal(files.has(old), true);
  }
});

test('bounded premium previews cannot be downloaded or turned into free loops', async () => {
  const { cache, downloads } = setup();
  await assert.rejects(cache.ensureLoopDownloaded('last-light', () => {}));
  assert.equal(downloads(), 0);
});
