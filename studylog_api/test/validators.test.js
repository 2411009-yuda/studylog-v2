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
  assert.deepEqual(value, { mataKuliahId: 5, topik: 'State', judul: 'J', isi: 'I' });
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
