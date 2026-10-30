'use strict';

// Menjalankan db/schema.sql lalu migrasi, tanpa perlu klien mysql di terminal.
// Aman untuk instalasi baru maupun database lama yang sudah berisi catatan.
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const { migrate } = require('./migrate');

(async () => {
  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || '127.0.0.1',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    multipleStatements: true,
    charset: 'utf8mb4',
  });
  const sql = fs.readFileSync(path.join(__dirname, '..', 'db', 'schema.sql'), 'utf8');
  await conn.query(sql);
  const berubah = await migrate(conn, 'studylog');
  await conn.end();
  console.log('Database studylog siap (skema + data awal).');
  if (berubah) console.log('Migrasi: kolom catatan.client_id ditambahkan.');
})().catch((e) => {
  console.error('Gagal menginisialisasi database:', e.message);
  process.exit(1);
});
