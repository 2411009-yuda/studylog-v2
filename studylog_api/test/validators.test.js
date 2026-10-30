'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { validateCatatan, parseId } = require('../src/validators');

const valid = { mataKuliahId: 5, topik: 'State', judul: 'Judul', isi: 'Isi' };

test('body valid diterima dan dirapikan', () => {
  const { value, error } = validateCatatan({
    ...valid, topik: '  State ', judul: ' J ', isi: ' I ',
  });
  assert.equal(error, undefined);
  assert.deepEqual(value, { mataKuliahId: 5, topik: "State", judul: "J", isi: "I", tanggal: null });
});

test('mataKuliahId wajib bilangan bulat positif', () => {
  for (const bad of [undefined, 'abc', 0, -1, 1.5]) {
    assert.equal(validateCatatan({ ...valid, mataKuliahId: bad }).error,
      'Mata kuliah wajib dipilih');
  }
});

test('field kosong atau hanya spasi ditolak', () => {
  assert.equal(validateCatatan({ ...valid, topik: '   ' }).error, 'Topik wajib diisi');
  assert.equal(validateCatatan({ ...valid, judul: '' }).error, 'Judul wajib diisi');
  assert.equal(validateCatatan({ ...valid, isi: '  ' }).error, 'Isi catatan wajib diisi');
});

test('topik minimal 3 karakter', () => {
  assert.equal(validateCatatan({ ...valid, topik: 'ab' }).error, 'Topik minimal 3 karakter');
});

test('body bukan objek ditolak tanpa melempar error', () => {
  assert.ok(validateCatatan(null).error);
  assert.ok(validateCatatan('teks').error);
});

test('parseId', () => {
  assert.equal(parseId('12'), 12);
  assert.equal(parseId('0'), null);
  assert.equal(parseId('abc'), null);
  assert.equal(parseId('1.5'), null);
});

const { parseTanggal, isUuid } = require('../src/validators');

test('parseTanggal: kosong = null, format valid dinormalkan', () => {
  assert.deepEqual(parseTanggal(undefined), { value: null });
  assert.deepEqual(parseTanggal(''), { value: null });
  assert.deepEqual(parseTanggal('2026-10-30 20:40:00'), { value: '2026-10-30 20:40:00' });
  assert.deepEqual(parseTanggal('2026-10-30T20:40'), { value: '2026-10-30 20:40:00' });
  assert.deepEqual(parseTanggal('2026-10-30T20:40:05.123'), { value: '2026-10-30 20:40:05' });
});

test('parseTanggal: format salah ditolak', () => {
  for (const bad of ['kemarin', '2026-13-01 10:00:00', '2026-10-30 25:00:00', 123, {}]) {
    assert.equal(parseTanggal(bad).error, 'Format tanggal tidak valid');
  }
});

test('validateCatatan menolak tanggal salah dan meneruskan tanggal valid', () => {
  assert.equal(validateCatatan({ ...valid, tanggal: 'x' }).error, 'Format tanggal tidak valid');
  assert.equal(validateCatatan({ ...valid, tanggal: '2026-10-30 20:40:00' }).value.tanggal,
    '2026-10-30 20:40:00');
  assert.equal(validateCatatan(valid).value.tanggal, null);
});

test('isUuid', () => {
  assert.ok(isUuid('123e4567-e89b-42d3-a456-426614174000'));
  assert.ok(!isUuid('bukan-uuid'));
  assert.ok(!isUuid(undefined));
});
