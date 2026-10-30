'use strict';

const { WebSocketServer } = require('ws');

/**
 * Hub WebSocket: menyiarkan kabar perubahan ke semua aplikasi yang terhubung.
 *
 * Pesan hanya PEMBERITAHUAN ("ada yang berubah"), bukan datanya. Aplikasi
 * menanggapinya dengan menarik data lewat jalur sinkronisasi biasa, sehingga
 * kabar yang terlewat (mis. koneksi sempat putus) tidak menyebabkan data
 * tertinggal: saat tersambung kembali aplikasi selalu menarik ulang.
 */
function createHub({ path = '/ws', heartbeatMs = 30000 } = {}) {
  let wss = null;
  let timer = null;

  const hub = {
    get jumlahKlien() {
      return wss ? wss.clients.size : 0;
    },

    /** Memasang WebSocket pada server HTTP yang sudah ada (port sama). */
    attach(server) {
      wss = new WebSocketServer({ server, path });

      wss.on('connection', (ws) => {
        ws.isAlive = true;
        ws.on('pong', () => { ws.isAlive = true; });
        ws.on('error', () => {});
        ws.send(JSON.stringify({ tipe: 'halo' }));
      });

      // Detak jantung: koneksi yang tidak menjawab ping (HP hilang sinyal,
      // laptop sleep) diputus agar tidak menumpuk.
      timer = setInterval(() => {
        for (const ws of wss.clients) {
          if (!ws.isAlive) { ws.terminate(); continue; }
          ws.isAlive = false;
          ws.ping();
        }
      }, heartbeatMs);
      timer.unref();
      return hub;
    },

    /** Mengirim [event] (objek JSON) ke semua klien yang sedang terhubung. */
    siarkan(event) {
      if (!wss) return;
      const data = JSON.stringify(event);
      for (const ws of wss.clients) {
        if (ws.readyState !== 1) continue; // 1 = OPEN
        ws.send(data, (err) => { if (err) ws.terminate(); });
      }
    },

    async close() {
      clearInterval(timer);
      if (!wss) return;
      for (const ws of wss.clients) ws.terminate();
      await new Promise((resolve) => wss.close(resolve));
    },
  };
  return hub;
}

module.exports = { createHub };
