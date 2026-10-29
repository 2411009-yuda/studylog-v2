/// Satu catatan kuliah. Immutable.
///
/// Pada M2 data hanya hidup di memori (ChangeNotifier). Id diberikan oleh
/// [CatatanStore]. Bentuk model ini sengaja disiapkan agar M3 hanya perlu
/// menambahkan konversi Map/JSON, tanpa mengubah layar.
class Catatan {
  const Catatan({
    this.id,
    required this.mataKuliah,
    required this.topik,
    required this.judul,
    required this.isi,
    required this.tanggal,
  });

  final int? id;
  final String mataKuliah;
  final String topik;
  final String judul;
  final String isi;
  final DateTime tanggal;

  /// Contoh: 30/10/2026
  String get tanggalLabel => '${tanggal.day}/${tanggal.month}/${tanggal.year}';
}
