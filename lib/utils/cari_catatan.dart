import '../models/catatan.dart';

/// Menyaring [daftar] berdasarkan [kueri]. Urutan daftar tidak diubah.
///
/// - Tidak membedakan huruf besar/kecil.
/// - Kueri dipecah menjadi kata; SEMUA kata harus ditemukan, tetapi boleh
///   tersebar di field berbeda (mis. "state pemrograman" cocok dengan topik
///   "State" pada mata kuliah "Pemrograman Aplikasi Bergerak").
/// - Field yang dicari: judul, topik, isi, nama dan kode mata kuliah.
/// - Kueri kosong/hanya spasi mengembalikan semua catatan.
List<Catatan> cariCatatan(List<Catatan> daftar, String kueri) {
  final kata = kueri
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((k) => k.isNotEmpty)
      .toList();
  if (kata.isEmpty) return List<Catatan>.of(daftar);

  return daftar.where((c) {
    final teks = [
      c.judul,
      c.topik,
      c.isi,
      c.mataKuliahNama,
      c.mataKuliahKode,
    ].join('\n').toLowerCase();
    return kata.every(teks.contains);
  }).toList();
}
