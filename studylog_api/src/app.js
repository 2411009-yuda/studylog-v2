'use strict';

const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const {
  validateCatatan, parseId, isUuid, validatePenilaian, parsePertemuan,
} = require('./validators');

const hhmm = (t) => String(t).slice(0, 5); // '19:00:00' -> '19:00'

const mapMataKuliah = (r) => ({
  id: r.id,
  kode: r.kode,
  nama: r.nama,
  sks: r.sks,
  dosen: r.dosen,
  deskripsi: r.deskripsi,
  prasyarat: r.prasyarat ? r.prasyarat.split('|').filter(Boolean) : [],
});

const mapJadwal = (r) => ({
  id: r.id,
  mataKuliahId: r.mata_kuliah_id,
  hari: r.hari,
  jamMulai: hhmm(r.jam_mulai),
  jamSelesai: hhmm(r.jam_selesai),
  kelas: r.kelas,
  ruang: r.ruang,
});

const mapCatatan = (r) => ({
  id: r.id,
  clientId: r.client_id,
  mataKuliahId: r.mata_kuliah_id,
  mataKuliahKode: r.kode,
  mataKuliahNama: r.nama,
  topik: r.topik,
  judul: r.judul,
  isi: r.isi,
  tanggal: r.tanggal, // 'YYYY-MM-DD HH:MM:SS' (dateStrings: true)
});

const mapPenilaian = (r) => ({
  id: r.id,
  mataKuliahId: r.mata_kuliah_id,
  pertemuan: r.pertemuan,
  skor: {
    penguasaan: r.skor_penguasaan,
    penyampaian: r.skor_penyampaian,
    kesesuaian: r.skor_kesesuaian,
    interaksi: r.skor_interaksi,
    disiplin: r.skor_disiplin,
  },
  komentar: r.komentar,
  dinilaiPada: r.diubah, // 'YYYY-MM-DD HH:MM:SS' (dateStrings: true)
});

const SELECT_CATATAN = `
  SELECT c.id, c.client_id, c.mata_kuliah_id, m.kode, m.nama,
         c.topik, c.judul, c.isi, c.tanggal
    FROM catatan c
    JOIN mata_kuliah m ON m.id = c.mata_kuliah_id`;

/**
 * Membuat aplikasi Express. [pool] = mysql2/promise pool.
 * [siarkan] dipanggil setelah data berubah (untuk real-time WebSocket).
 */
function createApp(pool, { siarkan = () => {} } = {}) {
  const app = express();

  // Kegagalan menyiarkan tidak boleh menggagalkan permintaan HTTP.
  const kabarkan = (aksi, id, clientId) => {
    try {
      siarkan({ tipe: 'catatan', aksi, id, clientId });
    } catch (e) {
      console.error('Gagal menyiarkan perubahan:', e.message);
    }
  };

  app.use(cors());
  app.use(express.json({ limit: '1mb' }));

  const wrap = (fn) => (req, res, next) => fn(req, res).catch(next);

  async function findCatatan(id) {
    const [rows] = await pool.query(`${SELECT_CATATAN} WHERE c.id = ?`, [id]);
    return rows[0] ? mapCatatan(rows[0]) : null;
  }

  app.get('/api/health', wrap(async (_req, res) => {
    await pool.query('SELECT 1');
    res.json({ status: 'ok' });
  }));

  // ---- Mata kuliah & jadwal (read-only) ----
  app.get('/api/mata-kuliah', wrap(async (_req, res) => {
    const [rows] = await pool.query('SELECT * FROM mata_kuliah ORDER BY nama');
    res.json(rows.map(mapMataKuliah));
  }));

  app.get('/api/jadwal', wrap(async (_req, res) => {
    const [rows] = await pool.query(
      'SELECT * FROM jadwal ORDER BY hari, jam_mulai');
    res.json(rows.map(mapJadwal));
  }));

  // ---- Catatan (CRUD) ----
  app.get('/api/catatan', wrap(async (_req, res) => {
    const [rows] = await pool.query(
      `${SELECT_CATATAN} ORDER BY c.tanggal DESC, c.id DESC`);
    res.json(rows.map(mapCatatan));
  }));

  app.get('/api/catatan/:id', wrap(async (req, res) => {
    const id = parseId(req.params.id);
    if (!id) return res.status(400).json({ error: 'ID tidak valid' });
    const catatan = await findCatatan(id);
    if (!catatan) return res.status(404).json({ error: 'Catatan tidak ditemukan' });
    res.json(catatan);
  }));

  app.post('/api/catatan', wrap(async (req, res) => {
    const { error, value } = validateCatatan(req.body);
    if (error) return res.status(400).json({ error });
    try {
      const clientId = crypto.randomUUID();
      const [result] = await pool.query(
        `INSERT INTO catatan (client_id, mata_kuliah_id, topik, judul, isi, tanggal)
         VALUES (?, ?, ?, ?, ?, COALESCE(?, NOW()))`,
        [clientId, value.mataKuliahId, value.topik, value.judul,
          value.isi, value.tanggal]);
      kabarkan('dibuat', result.insertId, clientId);
      res.status(201).json(await findCatatan(result.insertId));
    } catch (e) {
      if (e.code === 'ER_NO_REFERENCED_ROW_2') {
        return res.status(400).json({ error: 'Mata kuliah tidak ditemukan' });
      }
      throw e;
    }
  }));

  app.put('/api/catatan/:id', wrap(async (req, res) => {
    const id = parseId(req.params.id);
    if (!id) return res.status(400).json({ error: 'ID tidak valid' });
    const { error, value } = validateCatatan(req.body);
    if (error) return res.status(400).json({ error });
    if (!(await findCatatan(id))) {
      return res.status(404).json({ error: 'Catatan tidak ditemukan' });
    }
    try {
      await pool.query(
        `UPDATE catatan SET mata_kuliah_id = ?, topik = ?, judul = ?, isi = ?
          WHERE id = ?`,
        [value.mataKuliahId, value.topik, value.judul, value.isi, id]);
      const diubah = await findCatatan(id);
      kabarkan('diubah', id, diubah.clientId);
      res.json(diubah);
    } catch (e) {
      if (e.code === 'ER_NO_REFERENCED_ROW_2') {
        return res.status(400).json({ error: 'Mata kuliah tidak ditemukan' });
      }
      throw e;
    }
  }));

  app.delete('/api/catatan/:id', wrap(async (req, res) => {
    const id = parseId(req.params.id);
    if (!id) return res.status(400).json({ error: 'ID tidak valid' });
    const ada = await findCatatan(id);
    const [result] = await pool.query('DELETE FROM catatan WHERE id = ?', [id]);
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Catatan tidak ditemukan' });
    }
    kabarkan('dihapus', id, ada ? ada.clientId : null);
    res.status(204).end();
  }));

  // ---- Endpoint sinkronisasi (idempoten, dialamatkan dengan clientId) ----
  // Aman dikirim ulang berkali-kali: antrian offline di aplikasi memakainya.

  /** Buat jika belum ada, ubah jika sudah ada (clientId = identitas catatan). */
  app.put('/api/catatan/klien/:clientId', wrap(async (req, res) => {
    const clientId = String(req.params.clientId).toLowerCase();
    if (!isUuid(clientId)) return res.status(400).json({ error: 'clientId tidak valid' });
    const { error, value } = validateCatatan(req.body);
    if (error) return res.status(400).json({ error });

    const simpan = async () => {
      const [rows] = await pool.query(
        'SELECT id FROM catatan WHERE client_id = ?', [clientId]);
      if (rows[0]) {
        // Tanggal pembuatan tidak diubah oleh pembaruan.
        await pool.query(
          `UPDATE catatan SET mata_kuliah_id = ?, topik = ?, judul = ?, isi = ?
            WHERE client_id = ?`,
          [value.mataKuliahId, value.topik, value.judul, value.isi, clientId]);
        return { status: 200, id: rows[0].id };
      }
      const [result] = await pool.query(
        `INSERT INTO catatan (client_id, mata_kuliah_id, topik, judul, isi, tanggal)
         VALUES (?, ?, ?, ?, ?, COALESCE(?, NOW()))`,
        [clientId, value.mataKuliahId, value.topik, value.judul, value.isi,
          value.tanggal]);
      return { status: 201, id: result.insertId };
    };

    try {
      let hasil;
      try {
        hasil = await simpan();
      } catch (e) {
        // Dua permintaan dengan clientId sama bersamaan: ulangi sekali (jalur ubah).
        if (e.code !== 'ER_DUP_ENTRY') throw e;
        hasil = await simpan();
      }
      kabarkan(hasil.status === 201 ? 'dibuat' : 'diubah', hasil.id, clientId);
      res.status(hasil.status).json(await findCatatan(hasil.id));
    } catch (e) {
      if (e.code === 'ER_NO_REFERENCED_ROW_2') {
        return res.status(400).json({ error: 'Mata kuliah tidak ditemukan' });
      }
      throw e;
    }
  }));

  /** Hapus berdasarkan clientId. Selalu 204 (menghapus yang sudah hilang = berhasil). */
  app.delete('/api/catatan/klien/:clientId', wrap(async (req, res) => {
    const clientId = String(req.params.clientId).toLowerCase();
    if (!isUuid(clientId)) return res.status(400).json({ error: 'clientId tidak valid' });
    const [ada] = await pool.query(
      'SELECT id FROM catatan WHERE client_id = ?', [clientId]);
    const [result] = await pool.query(
      'DELETE FROM catatan WHERE client_id = ?', [clientId]);
    // Menghapus yang sudah tidak ada bukan perubahan: tidak perlu disiarkan.
    if (result.affectedRows > 0) kabarkan('dihapus', ada[0] ? ada[0].id : null, clientId);
    res.status(204).end();
  }));

  // ---- Penilaian dosen per pertemuan ----
  // Dialamatkan dengan (mataKuliahId, pertemuan) dan idempoten: PUT berulang
  // dengan isi sama menghasilkan keadaan yang sama.

  app.get('/api/penilaian', wrap(async (_req, res) => {
    const [rows] = await pool.query(
      'SELECT * FROM penilaian_dosen ORDER BY mata_kuliah_id, pertemuan');
    res.json(rows.map(mapPenilaian));
  }));

  /** Buat jika belum ada (201), ganti jika sudah ada (200). */
  app.put('/api/penilaian/:mataKuliahId/:pertemuan', wrap(async (req, res) => {
    const mataKuliahId = parseId(req.params.mataKuliahId);
    if (!mataKuliahId) return res.status(400).json({ error: 'ID mata kuliah tidak valid' });
    const pertemuan = parsePertemuan(req.params.pertemuan);
    if (!pertemuan) return res.status(400).json({ error: 'Pertemuan harus 1 sampai 16' });
    const { error, value } = validatePenilaian(req.body);
    if (error) return res.status(400).json({ error });

    try {
      const [ada] = await pool.query(
        'SELECT id FROM penilaian_dosen WHERE mata_kuliah_id = ? AND pertemuan = ?',
        [mataKuliahId, pertemuan]);
      const s = value.skor;
      await pool.query(
        `INSERT INTO penilaian_dosen
           (mata_kuliah_id, pertemuan, skor_penguasaan, skor_penyampaian,
            skor_kesesuaian, skor_interaksi, skor_disiplin, komentar)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
           skor_penguasaan = VALUES(skor_penguasaan),
           skor_penyampaian = VALUES(skor_penyampaian),
           skor_kesesuaian = VALUES(skor_kesesuaian),
           skor_interaksi = VALUES(skor_interaksi),
           skor_disiplin = VALUES(skor_disiplin),
           komentar = VALUES(komentar),
           diubah = NOW()`,
        [mataKuliahId, pertemuan, s.penguasaan, s.penyampaian, s.kesesuaian,
          s.interaksi, s.disiplin, value.komentar]);
      const [rows] = await pool.query(
        'SELECT * FROM penilaian_dosen WHERE mata_kuliah_id = ? AND pertemuan = ?',
        [mataKuliahId, pertemuan]);
      res.status(ada[0] ? 200 : 201).json(mapPenilaian(rows[0]));
    } catch (e) {
      if (e.code === 'ER_NO_REFERENCED_ROW_2') {
        return res.status(400).json({ error: 'Mata kuliah tidak ditemukan' });
      }
      throw e;
    }
  }));

  /** Hapus; selalu 204 (menghapus yang sudah hilang dianggap berhasil). */
  app.delete('/api/penilaian/:mataKuliahId/:pertemuan', wrap(async (req, res) => {
    const mataKuliahId = parseId(req.params.mataKuliahId);
    if (!mataKuliahId) return res.status(400).json({ error: 'ID mata kuliah tidak valid' });
    const pertemuan = parsePertemuan(req.params.pertemuan);
    if (!pertemuan) return res.status(400).json({ error: 'Pertemuan harus 1 sampai 16' });
    await pool.query(
      'DELETE FROM penilaian_dosen WHERE mata_kuliah_id = ? AND pertemuan = ?',
      [mataKuliahId, pertemuan]);
    res.status(204).end();
  }));

  app.use('/api', (_req, res) =>
    res.status(404).json({ error: 'Endpoint tidak ditemukan' }));

  // eslint-disable-next-line no-unused-vars
  app.use((err, _req, res, _next) => {
    if (err.type === 'entity.parse.failed') {
      return res.status(400).json({ error: 'Body bukan JSON yang valid' });
    }
    console.error(err);
    res.status(500).json({ error: 'Terjadi kesalahan pada server' });
  });

  return app;
}

module.exports = { createApp };
