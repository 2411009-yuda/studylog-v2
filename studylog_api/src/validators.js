'use strict';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const isUuid = (v) => typeof v === 'string' && UUID_RE.test(v);

/**
 * Tanggal opsional dari klien (waktu dinding, tanpa zona), mis.
 * '2026-10-30 20:40:00' atau '2026-10-30T20:40:00'.
 * Hasil: { value: 'YYYY-MM-DD HH:MM:SS' | null } atau { error }.
 */
function parseTanggal(raw) {
  if (raw === undefined || raw === null || raw === '') return { value: null };
  const m = typeof raw === 'string'
    ? raw.trim().match(/^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})(?::(\d{2}))?(?:\.\d+)?$/)
    : null;
  if (!m) return { error: 'Format tanggal tidak valid' };
  const [, y, mo, d, h, mi, se = '00'] = m;
  if (+mo < 1 || +mo > 12 || +d < 1 || +d > 31 || +h > 23 || +mi > 59 || +se > 59) {
    return { error: 'Format tanggal tidak valid' };
  }
  return { value: `${y}-${mo}-${d} ${h}:${mi}:${se}` };
}

/** Validasi body catatan. Mengembalikan { error } atau { value }. */
function validateCatatan(body) {
  const b = body && typeof body === 'object' ? body : {};
  const text = (v) => (typeof v === 'string' ? v.trim() : '');

  const mataKuliahId = Number(b.mataKuliahId);
  const topik = text(b.topik);
  const judul = text(b.judul);
  const isi = text(b.isi);

  if (!Number.isInteger(mataKuliahId) || mataKuliahId <= 0) {
    return { error: 'Mata kuliah wajib dipilih' };
  }
  if (!topik) return { error: 'Topik wajib diisi' };
  if (topik.length < 3) return { error: 'Topik minimal 3 karakter' };
  if (topik.length > 100) return { error: 'Topik maksimal 100 karakter' };
  if (!judul) return { error: 'Judul wajib diisi' };
  if (judul.length > 150) return { error: 'Judul maksimal 150 karakter' };
  if (!isi) return { error: 'Isi catatan wajib diisi' };

  const tanggal = parseTanggal(b.tanggal);
  if (tanggal.error) return { error: tanggal.error };

  return { value: { mataKuliahId, topik, judul, isi, tanggal: tanggal.value } };
}

function parseId(raw) {
  const id = Number(raw);
  return Number.isInteger(id) && id > 0 ? id : null;
}

module.exports = { validateCatatan, parseId, parseTanggal, isUuid };
