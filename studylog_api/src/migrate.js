'use strict';

/**
 * Migrasi skema untuk database yang dibuat sebelum fitur offline:
 * menambahkan kolom catatan.client_id (UUID), mengisi baris lama, dan
 * menjadikannya NOT NULL + UNIQUE. Idempoten: aman dijalankan berulang.
 * Mengembalikan true jika ada perubahan yang diterapkan.
 */
async function migrate(conn, dbName) {
  const [cols] = await conn.query(
    `SELECT COLUMN_NAME FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'catatan' AND COLUMN_NAME = 'client_id'`,
    [dbName]);
  if (cols.length > 0) return false;

  await conn.query('ALTER TABLE catatan ADD COLUMN client_id CHAR(36) NULL AFTER id');
  await conn.query('UPDATE catatan SET client_id = UUID() WHERE client_id IS NULL');
  await conn.query(
    `ALTER TABLE catatan
       MODIFY client_id CHAR(36) NOT NULL,
       ADD UNIQUE KEY uq_catatan_client (client_id)`);
  return true;
}

module.exports = { migrate };
