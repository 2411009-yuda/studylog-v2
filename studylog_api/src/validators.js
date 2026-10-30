'use strict';

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

  return { value: { mataKuliahId, topik, judul, isi } };
}

function parseId(raw) {
  const id = Number(raw);
  return Number.isInteger(id) && id > 0 ? id : null;
}

module.exports = { validateCatatan, parseId };
