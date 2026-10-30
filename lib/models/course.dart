/// Data mata kuliah (dari tabel mata_kuliah di MySQL).
class Course {
  const Course({
    required this.id,
    required this.kode,
    required this.nama,
    required this.sks,
    required this.dosen,
    required this.deskripsi,
    this.prasyarat = const [],
  });

  final int id;

  /// Kode mata kuliah. Juga dipakai sebagai argumen route detail
  /// (data dikirim seperlunya: cukup satu id).
  final String kode;
  final String nama;
  final int sks;
  final String dosen;
  final String deskripsi;
  final List<String> prasyarat;

  factory Course.fromJson(Map<String, dynamic> json) => Course(
        id: json['id'] as int,
        kode: json['kode'] as String,
        nama: json['nama'] as String,
        sks: json['sks'] as int,
        dosen: (json['dosen'] as String?) ?? '',
        deskripsi: (json['deskripsi'] as String?) ?? '',
        prasyarat: List<String>.from(
            (json['prasyarat'] as List<dynamic>?) ?? const []),
      );
}
