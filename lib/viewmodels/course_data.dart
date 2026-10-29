import '../models/course.dart';

/// Mata kuliah semester 5 sesuai kurikulum (Robotika tidak diambil).
/// Deskripsi singkat hanya penjelasan umum, bukan teks resmi RPS.
const List<Course> semesterCourses = [
  Course(
    kode: '000800',
    nama: 'Penulisan dan Publikasi Ilmiah',
    sks: 2,
    deskripsi:
        'Menyusun karya tulis ilmiah dan memahami proses publikasi '
        'pada jurnal maupun prosiding.',
    prasyarat: ['Metodologi Penelitian'],
  ),
  Course(
    kode: '110700',
    nama: 'Kriptografi',
    sks: 3,
    deskripsi:
        'Dasar-dasar penyandian data untuk menjaga kerahasiaan, '
        'keaslian, dan integritas informasi.',
  ),
  Course(
    kode: '111100',
    nama: 'Penalaran Komputer',
    sks: 3,
    deskripsi:
        'Representasi pengetahuan dan teknik penalaran agar komputer '
        'dapat menarik kesimpulan.',
    prasyarat: ['Kecerdasan Buatan'],
  ),
  Course(
    kode: '110600',
    nama: 'Jaringan Nirkabel',
    sks: 3,
    deskripsi:
        'Konsep, teknologi, dan perancangan jaringan komunikasi '
        'tanpa kabel.',
    prasyarat: ['Jaringan Komputer'],
  ),
  Course(
    kode: '111000',
    nama: 'Pemrograman Aplikasi Bergerak',
    sks: 3,
    deskripsi:
        'Membangun aplikasi mobile: antarmuka, state, navigasi, '
        'ViewModel, dan pengelolaan versi kode dengan Git.',
    prasyarat: ['Algoritme dan Pemrograman'],
  ),
  Course(
    kode: '111600',
    nama: 'Teknologi Aplikasi Bergerak',
    sks: 3,
    deskripsi:
        'Teknologi dan arsitektur pendukung aplikasi pada perangkat '
        'bergerak.',
    prasyarat: ['Komunikasi Data'],
  ),
  Course(
    kode: '111500',
    nama: 'Sistem Manajemen Basis Data',
    sks: 3,
    deskripsi:
        'Pengelolaan basis data melalui DBMS: penyimpanan, akses, '
        'dan keamanan data.',
    prasyarat: ['Sistem Basis Data'],
  ),
  Course(
    kode: '111400',
    nama: 'Simulasi dan Game Komputer',
    sks: 3,
    deskripsi:
        'Dasar simulasi dan pengembangan game komputer beserta '
        'logika permainannya.',
    prasyarat: ['Algoritma dan Pemrograman'],
  ),
];
