'use strict';

const http = require('http');
const { pool } = require('./db');
const { createApp } = require('./app');
const { createHub } = require('./hub');

const port = Number(process.env.PORT || 3000);

const hub = createHub();
const app = createApp(pool, { siarkan: hub.siarkan });
const server = http.createServer(app);
hub.attach(server); // WebSocket di port yang sama: ws://host:PORT/ws

// 0.0.0.0 agar dapat diakses emulator (10.0.2.2) dan perangkat di jaringan.
server.listen(port, '0.0.0.0', () => {
  console.log(`StudyLog API berjalan di http://localhost:${port}/api`);
  console.log(`Real-time (WebSocket) di ws://localhost:${port}/ws`);
});
