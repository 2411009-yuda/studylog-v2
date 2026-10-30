import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/models/jadwal.dart';
import 'package:profil_mahasiswa/utils/jadwal_utils.dart';

Jadwal j(int id, int mk, int hari, String mulai, String selesai) => Jadwal(
      id: id,
      mataKuliahId: mk,
      hari: hari,
      jamMulai: mulai,
      jamSelesai: selesai,
      kelas: 'IFB5J',
      ruang: 'R',
    );

// Senin: SMBD 19:00-20:30 (mk 7), TAB 20:30-22:00 (mk 6)
// Rabu : Kriptografi 20:30-22:00 (mk 2)
// Jumat: Jarnir 19:00-20:30 (mk 4), PAB 20:30-22:00 (mk 5)
final daftar = [
  j(1, 7, 1, '19:00', '20:30'),
  j(2, 6, 1, '20:30', '22:00'),
  j(5, 2, 3, '20:30', '22:00'),
  j(7, 4, 5, '19:00', '20:30'),
  j(8, 5, 5, '20:30', '22:00'),
];

// 2026-10-26 = Senin, 27 Selasa, 28 Rabu, 29 Kamis, 30 Jumat, 31 Sabtu
DateTime t(int tanggal, int jam, int menit) =>
    DateTime(2026, 10, tanggal, jam, menit);

void main() {
  test('Jadwal.label dan nama hari', () {
    expect(daftar.last.label, 'Jumat 20:30–22:00');
    expect(namaHari(1), 'Senin');
    expect(namaHari(7), 'Minggu');
  });

  group('cariJadwalUntukCatatan (tombol +)', () {
    test('kelas yang sedang berlangsung dipilih', () {
      expect(cariJadwalUntukCatatan(daftar, t(30, 19, 30))?.mataKuliahId, 4);
      expect(cariJadwalUntukCatatan(daftar, t(30, 21, 0))?.mataKuliahId, 5);
    });

    test('batas jam: mulai inklusif, selesai eksklusif', () {
      // 20:30 tepat -> kelas kedua sudah mulai.
      expect(cariJadwalUntukCatatan(daftar, t(30, 20, 30))?.mataKuliahId, 5);
      // 19:00 tepat -> kelas pertama.
      expect(cariJadwalUntukCatatan(daftar, t(30, 19, 0))?.mataKuliahId, 4);
    });

    test('setelah kelas terakhir selesai -> kelas yang baru selesai', () {
      expect(cariJadwalUntukCatatan(daftar, t(30, 22, 30))?.mataKuliahId, 5);
    });

    test('sebelum kelas pertama hari ini -> kelas berikutnya', () {
      expect(cariJadwalUntukCatatan(daftar, t(30, 14, 0))?.mataKuliahId, 4);
    });

    test('hari tanpa kelas -> null', () {
      expect(cariJadwalUntukCatatan(daftar, t(29, 20, 0)), isNull); // Kamis
      expect(cariJadwalUntukCatatan(daftar, t(31, 10, 0)), isNull); // Sabtu
    });

    test('daftar kosong -> null', () {
      expect(cariJadwalUntukCatatan(const [], t(30, 20, 0)), isNull);
    });
  });

  group('cariJadwalTerdekat (kartu Beranda)', () {
    test('sedang berlangsung', () {
      final r = cariJadwalTerdekat(daftar, t(30, 20, 40))!;
      expect(r.berlangsung, isTrue);
      expect(r.jadwal.mataKuliahId, 5);
    });

    test('berikutnya pada hari yang sama', () {
      final r = cariJadwalTerdekat(daftar, t(30, 18, 0))!;
      expect(r.berlangsung, isFalse);
      expect(r.jadwal.mataKuliahId, 4);
    });

    test('berikutnya pada hari lain', () {
      // Kamis -> kelas berikutnya adalah Jumat 19:00.
      final r = cariJadwalTerdekat(daftar, t(29, 12, 0))!;
      expect(r.jadwal.mataKuliahId, 4);
    });

    test('melewati akhir pekan kembali ke Senin', () {
      // Jumat 23:00 -> Senin 19:00.
      final r = cariJadwalTerdekat(daftar, t(30, 23, 0))!;
      expect(r.berlangsung, isFalse);
      expect(r.jadwal.mataKuliahId, 7);
    });

    test('daftar kosong -> null', () {
      expect(cariJadwalTerdekat(const [], t(30, 20, 0)), isNull);
    });
  });
}
