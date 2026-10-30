'use strict';

// Menjalankan db/schema.sql tanpa perlu klien mysql di terminal.
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');

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
  await conn.end();
  console.log('Database studylog siap (skema + data awal).');
})().catch((e) => {
  console.error('Gagal menginisialisasi database:', e.message);
  process.exit(1);
});
