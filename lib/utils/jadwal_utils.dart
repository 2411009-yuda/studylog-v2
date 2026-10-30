import '../models/jadwal.dart';

/// Memilih jadwal untuk mengisi mata kuliah pada catatan baru (tombol +).
///
/// Aturan, hanya memperhatikan jadwal HARI INI:
/// 1. kelas yang sedang berlangsung;
/// 2. jika tidak ada, kelas yang paling akhir selesai (catatan ditulis
///    sesudah kuliah);
/// 3. jika belum ada kelas yang selesai, kelas berikutnya hari ini;
/// 4. jika hari ini tidak ada kelas: null (pengguna memilih manual).
Jadwal? cariJadwalUntukCatatan(List<Jadwal> daftar, DateTime sekarang) {
  final menit = sekarang.hour * 60 + sekarang.minute;
  final hariIni = daftar.where((j) => j.hari == sekarang.weekday).toList()
    ..sort((a, b) => a.menitMulai.compareTo(b.menitMulai));

  for (final j in hariIni) {
    if (menit >= j.menitMulai && menit < j.menitSelesai) return j;
  }

  Jadwal? terakhirSelesai;
  for (final j in hariIni) {
    if (j.menitSelesai <= menit) terakhirSelesai = j;
  }
  if (terakhirSelesai != null) return terakhirSelesai;

  for (final j in hariIni) {
    if (j.menitMulai > menit) return j;
  }
  return null;
}

typedef JadwalTerdekat = ({Jadwal jadwal, bool berlangsung});

/// Kelas yang sedang berlangsung, atau kelas berikutnya dalam sepekan
/// (menyeberang hari dan kembali ke awal pekan jika perlu).
JadwalTerdekat? cariJadwalTerdekat(List<Jadwal> daftar, DateTime sekarang) {
  const menitPerHari = 1440;
  const menitPerPekan = 7 * menitPerHari;
  final posisi = (sekarang.weekday - 1) * menitPerHari +
      sekarang.hour * 60 +
      sekarang.minute;

  Jadwal? terbaik;
  int? selisihTerbaik;
  for (final j in daftar) {
    final mulai = (j.hari - 1) * menitPerHari + j.menitMulai;
    final selesai = (j.hari - 1) * menitPerHari + j.menitSelesai;
    if (posisi >= mulai && posisi < selesai) {
      return (jadwal: j, berlangsung: true);
    }
    final selisih = (mulai - posisi) % menitPerPekan;
    if (selisihTerbaik == null || selisih < selisihTerbaik) {
      selisihTerbaik = selisih;
      terbaik = j;
    }
  }
  return terbaik == null ? null : (jadwal: terbaik, berlangsung: false);
}
