/// Informasi aplikasi yang ditampilkan di halaman "Tentang Aplikasi".
///
/// [versi] harus sama dengan bagian sebelum tanda '+' pada `version:` di
/// pubspec.yaml (dijaga oleh test/tentang_test.dart).
class AppInfo {
  static const nama = 'StudyLog';
  static const tagline = 'Aplikasi Catatan Perkuliahan';
  static const versi = '1.0.0';
  static const institusi = 'Universitas Mulia';
  static const mataKuliah = 'Pemrograman Aplikasi Bergerak';
  static const tahun = 2026;

  static const deskripsi =
      'StudyLog membantu mahasiswa mencatat materi kuliah, mencari dan '
      'mengurutkannya, lalu membagikannya. Catatan tersimpan di perangkat '
      'sehingga tetap bisa dipakai tanpa internet, dan otomatis disinkronkan '
      'ke server saat terhubung.';

  /// (ikon-nama, judul, keterangan) ditampilkan sebagai daftar fitur.
  static const fitur = <({String judul, String keterangan})>[
    (
      judul: 'Catat dengan cepat',
      keterangan:
          'Tombol + mengisi mata kuliah otomatis sesuai jadwal kuliah hari ini.',
    ),
    (
      judul: 'Tetap bisa offline',
      keterangan:
          'Perubahan masuk antrian dan terkirim sendiri saat koneksi kembali.',
    ),
    (
      judul: 'Real-time',
      keterangan:
          'Catatan dari perangkat lain muncul tanpa perlu menyegarkan halaman.',
    ),
    (
      judul: 'Urutkan dan ekspor',
      keterangan: 'Urutkan daftar, lalu salin atau bagikan sebagai teks.',
    ),
  ];

  static const teknologi = <String>[
    'Flutter',
    'Dart',
    'Provider',
    'SQLite',
    'Node.js',
    'MySQL',
    'WebSocket',
  ];
}
