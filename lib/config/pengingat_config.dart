/// Pengaturan fitur pengingat (penilaian dosen & catatan kelas).
///
/// Aplikasi belum punya data tanggal pertemuan, jadi jumlah pertemuan yang
/// sudah berlangsung dihitung dari tanggal mulai kuliah semester ini.
/// UBAH [awalSemesterBawaan] setiap semester (cukup tanggal minggu pertama
/// kuliah; hari kelas dihitung dari tabel jadwal).
final DateTime awalSemesterBawaan = DateTime(2026, 9, 7);

/// Jam pengingat harian (waktu perangkat).
const int jamPengingatBawaan = 19;
const int menitPengingatBawaan = 0;

/// Kelas yang belum dicatat hanya diingatkan sampai sekian hari ke belakang,
/// supaya kelas yang sudah lama lewat tidak menumpuk.
const int hariMundurKelas = 7;

/// Zona waktu jadwal pengingat (WITA, Balikpapan).
const String zonaWaktuPengingat = 'Asia/Makassar';
