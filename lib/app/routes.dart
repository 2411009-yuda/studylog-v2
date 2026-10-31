/// Daftar route aplikasi. Satu destination = satu route bernama sederhana.
///
/// Home ('/') adalah shell dengan bottom navigation: Beranda, Profil,
/// Mata Kuliah, Kontak. Route di bawah ini adalah layar yang DITUMPUKKAN
/// di atas shell (push/pop).
class AppRoutes {
  static const home = '/';

  // StudyLog
  static const tentang = '/tentang';
  static const daftar = '/catatan';
  static const detail = '/catatan/detail';
  static const form = '/catatan/form';

  // Fitur profil mahasiswa
  static const courseDetail = '/mata-kuliah';
  static const contact = '/kontak'; // juga dipakai tombol "Lihat Kontak"
}
