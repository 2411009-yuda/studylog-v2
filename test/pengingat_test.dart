import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/models/catatan.dart';
import 'package:profil_mahasiswa/models/course.dart';
import 'package:profil_mahasiswa/models/jadwal.dart';
import 'package:profil_mahasiswa/utils/pengingat_utils.dart';

const course = Course(
  id: 1,
  kode: 'IF501',
  nama: 'Pemrograman Aplikasi Bergerak',
  sks: 3,
  dosen: 'Dosen',
  deskripsi: '',
);

// Jumat 20:30-22:00.
const jumat = Jadwal(
  id: 1,
  mataKuliahId: 1,
  hari: 5,
  jamMulai: '20:30',
  jamSelesai: '22:00',
  kelas: 'IFB5J',
  ruang: 'R1',
);

// Senin 7 Sep 2026; Jumat pertama = 11 Sep.
final awal = DateTime(2026, 9, 7);

// Jumat 30 Okt 2026 = Jumat ke-8.
final jumatSelesai = DateTime(2026, 10, 30, 22, 30);
final jumatBerlangsung = DateTime(2026, 10, 30, 20, 40);

Catatan catatanPada(DateTime t, {int mk = 1}) => Catatan(
      mataKuliahId: mk,
      topik: 't',
      judul: 'j',
      isi: 'i',
      tanggal: t,
    );

void main() {
  group('sesiSelesai', () {
    test('menghitung Jumat yang sudah selesai', () {
      expect(sesiSelesai(jumat, awal, jumatSelesai), 8);
    });

    test('sesi yang masih berlangsung belum dihitung', () {
      expect(sesiSelesai(jumat, awal, jumatBerlangsung), 7);
    });

    test('0 sebelum semester dimulai', () {
      expect(sesiSelesai(jumat, awal, DateTime(2026, 9, 1)), 0);
    });

    test('dibatasi 16 pertemuan', () {
      expect(sesiSelesai(jumat, awal, DateTime(2027, 6, 1)), 16);
    });
  });

  group('cariPenilaianTerlewat', () {
    List<Pengingat> hitung(Set<int> dinilai, DateTime sekarang) =>
        cariPenilaianTerlewat(
          courses: const [course],
          jadwal: const [jumat],
          pertemuanDinilai: (_) => dinilai,
          awalSemester: awal,
          sekarang: sekarang,
        );

    test('melaporkan pertemuan yang belum dinilai', () {
      final hasil = hitung({1, 2, 3}, jumatSelesai);
      expect(hasil, hasLength(1));
      expect(hasil.single.jumlah, 5); // pertemuan 4..8
      expect(hasil.single.detail, contains('Pertemuan 4, 5, 6, 7, dst.'));
    });

    test('kosong jika semua pertemuan yang berlangsung sudah dinilai', () {
      expect(hitung({1, 2, 3, 4, 5, 6, 7, 8}, jumatSelesai), isEmpty);
    });

    test('penilaian pertemuan yang belum terjadi tidak mengurangi', () {
      final hasil = hitung({1, 2, 3, 4, 5, 6, 7, 12}, jumatSelesai);
      expect(hasil.single.jumlah, 1); // hanya pertemuan 8
    });
  });

  group('cariKelasTanpaCatatan', () {
    List<Pengingat> hitung(List<Catatan> catatan, DateTime sekarang) =>
        cariKelasTanpaCatatan(
          courses: const [course],
          jadwal: const [jumat],
          catatan: catatan,
          awalSemester: awal,
          sekarang: sekarang,
        );

    test('kelas selesai tanpa catatan diingatkan', () {
      final hasil = hitung([], jumatSelesai);
      expect(hasil, hasLength(1));
      expect(hasil.single.detail, 'Kelas Jumat 30/10 belum dicatat');
      expect(hasil.single.jadwal, jumat);
    });

    test('kelas yang masih berlangsung belum diingatkan', () {
      expect(hitung([], jumatBerlangsung), isEmpty);
    });

    test('catatan mata kuliah yang sama pada hari itu menghapus pengingat',
        () {
      final c = catatanPada(DateTime(2026, 10, 30, 21, 50));
      expect(hitung([c], jumatSelesai), isEmpty);
    });

    test('catatan mata kuliah lain tidak dihitung', () {
      final c = catatanPada(DateTime(2026, 10, 30, 21, 50), mk: 2);
      expect(hitung([c], jumatSelesai), hasLength(1));
    });

    test('hanya melihat 7 hari terakhir', () {
      // Sabtu 7 Nov: jendela 1-7 Nov hanya memuat Jumat 6 Nov; Jumat 30 Okt
      // sudah di luar jendela.
      final hasil = hitung([], DateTime(2026, 11, 7, 10));
      expect(hasil, hasLength(1));
      expect(hasil.single.detail, 'Kelas Jumat 6/11 belum dicatat');
    });
  });

  test('ringkasanPengingat menjumlahkan per jenis', () {
    final teks = ringkasanPengingat(const [
      Pengingat(
        jenis: JenisPengingat.penilaian,
        mataKuliahId: 1,
        mataKuliahKode: 'IF501',
        judul: 'A',
        detail: 'x',
        jumlah: 3,
      ),
      Pengingat(
        jenis: JenisPengingat.kelas,
        mataKuliahId: 1,
        mataKuliahKode: 'IF501',
        judul: 'A',
        detail: 'y',
      ),
    ]);
    expect(teks.isi, '3 pertemuan belum dinilai · 1 kelas belum dicatat');
  });

  test('labelTanggalWaktu', () {
    expect(labelTanggalWaktu(DateTime(2026, 11, 19, 9, 5)),
        '19/11/2026 pukul 09:05');
  });
}
