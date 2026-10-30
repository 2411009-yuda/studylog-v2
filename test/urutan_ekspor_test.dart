import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/models/catatan.dart';
import 'package:profil_mahasiswa/utils/ekspor_teks.dart';
import 'package:profil_mahasiswa/utils/urutan_catatan.dart';

Catatan c(int id, String judul, DateTime tanggal) => Catatan(
      id: id,
      mataKuliahId: 5,
      mataKuliahKode: '111000',
      mataKuliahNama: 'Pemrograman Aplikasi Bergerak',
      topik: 'State',
      judul: judul,
      isi: 'Isi $judul',
      tanggal: tanggal,
    );

void main() {
  final bumi = c(1, 'bumi', DateTime(2026, 10, 28, 10));
  final awan = c(2, 'Awan', DateTime(2026, 10, 29, 10));
  final cahaya = c(3, 'Cahaya', DateTime(2026, 10, 30, 10));
  final acak = [awan, cahaya, bumi];

  group('urutkanCatatan', () {
    test('terbaru: tanggal menurun', () {
      expect(urutkanCatatan(acak, UrutanCatatan.terbaru),
          [cahaya, awan, bumi]);
    });

    test('terlama: tanggal menaik', () {
      expect(urutkanCatatan(acak, UrutanCatatan.terlama),
          [bumi, awan, cahaya]);
    });

    test('judul A-Z tidak membedakan huruf besar/kecil', () {
      expect(urutkanCatatan(acak, UrutanCatatan.judulAZ),
          [awan, bumi, cahaya]);
    });

    test('tanggal sama: id menentukan (terbaru = id terbesar dulu)', () {
      final t = DateTime(2026, 10, 30);
      final a = c(1, 'A', t);
      final b = c(2, 'B', t);
      expect(urutkanCatatan([a, b], UrutanCatatan.terbaru), [b, a]);
      expect(urutkanCatatan([b, a], UrutanCatatan.terlama), [a, b]);
    });

    test('judul sama: id menentukan agar urutan stabil', () {
      final t = DateTime(2026, 10, 30);
      final a = c(1, 'Sama', t);
      final b = c(2, 'sama', t);
      expect(urutkanCatatan([b, a], UrutanCatatan.judulAZ), [a, b]);
    });

    test('tidak mengubah daftar asli', () {
      final asli = [awan, cahaya, bumi];
      urutkanCatatan(asli, UrutanCatatan.judulAZ);
      expect(asli, [awan, cahaya, bumi]);
    });

    test('daftar kosong', () {
      expect(urutkanCatatan(const [], UrutanCatatan.terbaru), isEmpty);
    });

    test('label urutan', () {
      expect(UrutanCatatan.values.map((u) => u.label),
          ['Terbaru', 'Terlama', 'Judul A–Z']);
    });
  });

  group('ekspor teks', () {
    test('eksporSatu memuat semua bagian catatan', () {
      final teks = eksporSatu(cahaya);
      expect(teks, startsWith('CAHAYA\n'));
      expect(teks, contains('Mata kuliah : Pemrograman Aplikasi Bergerak (111000)'));
      expect(teks, contains('Topik       : State'));
      expect(teks, contains('Dibuat      : 30/10/2026 10:00'));
      expect(teks, endsWith('Isi Cahaya'));
    });

    test('eksporSatu tanpa kode mata kuliah tidak memakai tanda kurung', () {
      final tanpaKode = Catatan(
        mataKuliahId: 1,
        mataKuliahNama: 'Kriptografi',
        topik: 'Cipher',
        judul: 'J',
        isi: 'I',
        tanggal: DateTime(2026, 1, 1),
      );
      expect(eksporSatu(tanpaKode), contains('Mata kuliah : Kriptografi\n'));
    });

    test('eksporSemua: header, jumlah, urutan, dan penomoran', () {
      final teks = eksporSemua(
        [cahaya, awan],
        waktu: DateTime(2026, 10, 30, 21, 5),
        urutan: 'Terbaru',
      );
      expect(teks, startsWith('StudyLog - Ekspor Catatan'));
      expect(teks, contains('Diekspor : 30/10/2026 21:05'));
      expect(teks, contains('Jumlah   : 2 catatan'));
      expect(teks, contains('Urutan   : Terbaru'));
      expect(teks.indexOf('[1] CAHAYA'), lessThan(teks.indexOf('[2] AWAN')));
      expect(teks, isNot(endsWith('\n')));
    });
  });
}
