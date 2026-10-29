/// Data mata kuliah untuk layar Detail Mata Kuliah.
class Course {
  const Course({
    required this.kode,
    required this.nama,
    required this.sks,
    required this.deskripsi,
    this.prasyarat = const [],
  });

  /// Kode mata kuliah. Juga dipakai sebagai argumen route
  /// (data dikirim seperlunya: cukup satu id).
  final String kode;
  final String nama;
  final int sks;
  final String deskripsi;
  final List<String> prasyarat;
}
