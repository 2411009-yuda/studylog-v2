import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/models/catatan.dart';

void main() {
  test('Catatan round-trip JSON tidak mengubah data', () {
    final asli = Catatan(
      id: 1, // id lokal tidak ikut ke server
      clientId: '11111111-1111-4111-8111-111111111111',
      serverId: 10,
      mataKuliahId: 5,
      mataKuliahKode: '111000',
      mataKuliahNama: 'Pemrograman Aplikasi Bergerak',
      topik: 'MySQL',
      judul: 'REST API',
      isi: 'Materi CRUD',
      tanggal: DateTime(2026, 10, 22, 19, 5),
    );

    final hasil = Catatan.fromJson(asli.toJson());

    expect(hasil.serverId, 10);
    expect(hasil.clientId, asli.clientId);
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
      'clientId': 'abc',
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
    expect(c.tanggalServer, '2026-10-30 07:05:09');
  });

  test('catatan yang belum pernah terkirim tidak punya id server', () {
    final c = Catatan(
      mataKuliahId: 5,
      topik: 'abc',
      judul: 'j',
      isi: 'i',
      tanggal: DateTime(2026, 1, 2, 3, 4, 5),
    );
    expect(c.serverId, isNull);
    expect(c.toJson().containsKey('id'), isFalse);
    expect(c.tanggalServer, '2026-01-02 03:04:05');
  });

  test('toRequestBody memuat field yang diterima server, termasuk tanggal', () {
    final c = Catatan(
      id: 3,
      clientId: 'x',
      serverId: 9,
      mataKuliahId: 5,
      topik: 'abc',
      judul: 'j',
      isi: 'i',
      tanggal: DateTime(2026, 1, 1, 8),
    );
    expect(c.toRequestBody(), {
      'mataKuliahId': 5,
      'topik': 'abc',
      'judul': 'j',
      'isi': 'i',
      'tanggal': '2026-01-01 08:00:00',
    });
  });

  test('copyWith mempertahankan identitas dan mengubah field yang diminta', () {
    final c = Catatan(
      id: 3,
      clientId: 'x',
      serverId: 9,
      mataKuliahId: 5,
      topik: 'abc',
      judul: 'lama',
      isi: 'i',
      tanggal: DateTime(2026, 1, 1),
    );
    final u = c.copyWith(judul: 'baru', menunggu: true);
    expect(u.judul, 'baru');
    expect(u.menunggu, isTrue);
    expect([u.id, u.clientId, u.serverId], [3, 'x', 9]);
  });
}
