'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const WebSocket = require('ws');
const { createHub } = require('../src/hub');

/** Menjalankan hub pada server HTTP di port acak. */
async function mulai(opsi) {
  const hub = createHub(opsi);
  const server = http.createServer((_req, res) => res.end('ok'));
  hub.attach(server);
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const url = `ws://127.0.0.1:${server.address().port}/ws`;
  const tutup = async () => {
    await hub.close();
    await new Promise((r) => server.close(r));
  };
  return { hub, server, url, tutup };
}

/** Membuka klien dan mengumpulkan semua pesan yang diterima. */
function klien(url, opsi) {
  const ws = new WebSocket(url, opsi);
  const pesan = [];
  ws.on('message', (d) => pesan.push(JSON.parse(d.toString())));
  const siap = new Promise((resolve, reject) => {
    ws.on('open', resolve);
    ws.on('error', reject);
  });
  return { ws, pesan, siap };
}

const tunggu = (ms) => new Promise((r) => setTimeout(r, ms));

test('klien baru menerima sapaan "halo"', async () => {
  const { url, tutup } = await mulai();
  const k = klien(url);
  await k.siap;
  await tunggu(50);
  assert.deepEqual(k.pesan, [{ tipe: 'halo' }]);
  k.ws.close();
  await tutup();
});

test('siarkan: semua klien menerima event yang sama', async () => {
  const { hub, url, tutup } = await mulai();
  const a = klien(url);
  const b = klien(url);
  await Promise.all([a.siap, b.siap]);

  hub.siarkan({ tipe: 'catatan', aksi: 'dibuat', id: 1, clientId: 'x' });
  await tunggu(80);

  const event = { tipe: 'catatan', aksi: 'dibuat', id: 1, clientId: 'x' };
  assert.deepEqual(a.pesan.at(-1), event);
  assert.deepEqual(b.pesan.at(-1), event);
  a.ws.close();
  b.ws.close();
  await tutup();
});

test('klien yang sudah terputus dilepas dan tidak mengganggu siaran', async () => {
  const { hub, url, tutup } = await mulai();
  const a = klien(url);
  const b = klien(url);
  await Promise.all([a.siap, b.siap]);
  assert.equal(hub.jumlahKlien, 2);

  a.ws.terminate();
  await tunggu(80);
  assert.equal(hub.jumlahKlien, 1);

  hub.siarkan({ tipe: 'catatan', aksi: 'diubah', id: 2, clientId: 'y' });
  await tunggu(80);
  assert.equal(b.pesan.at(-1).aksi, 'diubah');
  b.ws.close();
  await tutup();
});

test('siarkan tanpa klien atau sebelum attach tidak melempar error', async () => {
  createHub().siarkan({ tipe: 'catatan' }); // belum attach
  const { hub, tutup } = await mulai();
  hub.siarkan({ tipe: 'catatan' }); // tanpa klien
  await tutup();
});

test('heartbeat memutus klien yang tidak menjawab ping', async () => {
  const { hub, url, tutup } = await mulai({ heartbeatMs: 40 });
  // Klien "membeku": tidak membalas ping server (autoPong dimatikan).
  const k = klien(url, { autoPong: false });
  await k.siap;
  await tunggu(300);
  assert.equal(hub.jumlahKlien, 0);
  await tutup();
});

test('klien yang sehat tetap terhubung melewati beberapa heartbeat', async () => {
  const { hub, url, tutup } = await mulai({ heartbeatMs: 40 });
  const k = klien(url);
  await k.siap;
  await tunggu(250);
  assert.equal(hub.jumlahKlien, 1);
  k.ws.close();
  await tutup();
});
