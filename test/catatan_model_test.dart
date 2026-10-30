import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/models/catatan.dart';

void main() {
  test('Catatan round-trip JSON tidak mengubah data', () {
    final asli = Catatan(
      id: 10,
      mataKuliahId: 5,
      mataKuliahKode: '111000',
      mataKuliahNama: 'Pemrograman Aplikasi Bergerak',
      topik: 'MySQL',
      judul: 'REST API',
      isi: 'Materi CRUD',
      tanggal: DateTime(2026, 10, 22, 19, 5),
    );

    final hasil = Catatan.fromJson(asli.toJson());

    expect(hasil.id, 10);
    expect(hasil.mataKuliahId, 5);
    expect(hasil.mataKuliahNama, 'Pemrograman Aplikasi Bergerak');
    expect(hasil.topik, 'MySQL');
    expect(hasil.judul, 'REST API');
    expect(hasil.isi, 'Materi CRUD');
    expect(hasil.tanggal, DateTime(2026, 10, 22, 19, 5));
  });

  test('fromJson membaca format tanggal server (YYYY-MM-DD HH:MM:SS)', () {
    final c = Catatan.fromJson({
      'id': 1,
      'mataKuliahId': 2,
      'mataKuliahKode': '110700',
      'mataKuliahNama': 'Kriptografi',
      'topik': 'Cipher',
      'judul': 'J',
      'isi': 'I',
      'tanggal': '2026-10-30 07:05:09',
    });
    expect(c.tanggalLabel, '30/10/2026');
    expect(c.tanggalWaktuLabel, '30/10/2026 07:05');
  });

  test('toRequestBody hanya berisi field yang diterima server', () {
    final c = Catatan(
      id: 3,
      mataKuliahId: 5,
      topik: 'abc',
      judul: 'j',
      isi: 'i',
      tanggal: DateTime(2026, 1, 1),
    );
    expect(c.toRequestBody().keys.toSet(),
        {'mataKuliahId', 'topik', 'judul', 'isi'});
  });
}
