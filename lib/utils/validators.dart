/// Fungsi validasi murni (tanpa dependensi UI) agar mudah diuji.
/// Dipakai oleh TextFormField.validator pada form catatan StudyLog.

String? validateWajibIsi(String? nilai, String label) {
  if (nilai == null || nilai.trim().isEmpty) return '$label wajib diisi';
  return null;
}

/// Latihan mandiri Praktikum 1: Topik minimal tiga karakter.
String? validateTopik(String? nilai) {
  final teks = (nilai ?? '').trim();
  if (teks.isEmpty) return 'Topik wajib diisi';
  if (teks.length < 3) return 'Topik minimal 3 karakter';
  return null;
}
