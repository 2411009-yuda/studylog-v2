/// Satu catatan kuliah. Immutable. Data tersimpan di MySQL lewat API.
class Catatan {
  const Catatan({
    this.id,
    required this.mataKuliahId,
    this.mataKuliahKode = '',
    this.mataKuliahNama = '',
    required this.topik,
    required this.judul,
    required this.isi,
    required this.tanggal,
  });

  final int? id;
  final int mataKuliahId;
  final String mataKuliahKode;
  final String mataKuliahNama;
  final String topik;
  final String judul;
  final String isi;
  final DateTime tanggal;

  /// Bentuk lengkap (dipakai untuk uji round-trip).
  Map<String, Object?> toJson() => {
        if (id != null) 'id': id,
        'mataKuliahId': mataKuliahId,
        'mataKuliahKode': mataKuliahKode,
        'mataKuliahNama': mataKuliahNama,
        'topik': topik,
        'judul': judul,
        'isi': isi,
        'tanggal': tanggal.toIso8601String(),
      };

  /// Body untuk POST/PUT. Tanggal dan nama mata kuliah diurus server.
  Map<String, Object?> toRequestBody() => {
        'mataKuliahId': mataKuliahId,
        'topik': topik,
        'judul': judul,
        'isi': isi,
      };

  factory Catatan.fromJson(Map<String, dynamic> json) => Catatan(
        id: json['id'] as int?,
        mataKuliahId: json['mataKuliahId'] as int,
        mataKuliahKode: (json['mataKuliahKode'] as String?) ?? '',
        mataKuliahNama: (json['mataKuliahNama'] as String?) ?? '',
        topik: json['topik'] as String,
        judul: json['judul'] as String,
        isi: json['isi'] as String,
        // Menerima 'YYYY-MM-DD HH:MM:SS' (server) maupun format ISO 8601.
        tanggal: DateTime.parse(json['tanggal'] as String),
      );

  static String _dua(int n) => n.toString().padLeft(2, '0');

  /// Contoh: 30/10/2026
  String get tanggalLabel => '${tanggal.day}/${tanggal.month}/${tanggal.year}';

  /// Contoh: 30/10/2026 19:05
  String get tanggalWaktuLabel =>
      '$tanggalLabel ${_dua(tanggal.hour)}:${_dua(tanggal.minute)}';
}
