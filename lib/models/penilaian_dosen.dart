/// Satu aspek yang dinilai pada evaluasi dosen per pertemuan.
class AspekPenilaian {
  const AspekPenilaian(this.kode, this.label, this.keterangan);

  final String kode;
  final String label;
  final String keterangan;
}

/// Aspek penilaian umum pada evaluasi kinerja dosen (skala Likert 1-5).
const aspekPenilaian = <AspekPenilaian>[
  AspekPenilaian('penguasaan', 'Penguasaan materi',
      'Dosen menguasai dan menjelaskan materi dengan benar.'),
  AspekPenilaian('penyampaian', 'Kejelasan penyampaian',
      'Penjelasan runtut, jelas, dan mudah dipahami.'),
  AspekPenilaian('kesesuaian', 'Kesesuaian dengan RPS',
      'Materi yang diajarkan sesuai rencana pembelajaran.'),
  AspekPenilaian('interaksi', 'Interaksi dan respons',
      'Dosen terbuka terhadap pertanyaan dan diskusi.'),
  AspekPenilaian('disiplin', 'Ketepatan waktu dan disiplin',
      'Kelas dimulai dan diakhiri tepat waktu.'),
];

/// Jumlah pertemuan tatap muka per semester.
const jumlahPertemuan = 16;

const skorMin = 1;
const skorMaks = 5;

const labelSkor = <int, String>{
  1: 'Sangat kurang',
  2: 'Kurang',
  3: 'Cukup',
  4: 'Baik',
  5: 'Sangat baik',
};

/// Kategori dari skor rata-rata (skala 1-5).
String kategoriSkor(double rata) {
  if (rata >= 4.5) return 'Sangat baik';
  if (rata >= 3.5) return 'Baik';
  if (rata >= 2.5) return 'Cukup';
  if (rata >= 1.5) return 'Kurang';
  return 'Sangat kurang';
}

/// Contoh: 4.25 -> "4,3" (satu desimal, koma sebagai pemisah).
String formatSkor(double nilai) => nilai.toStringAsFixed(1).replaceAll('.', ',');

/// Penilaian mahasiswa terhadap dosen pada satu pertemuan mata kuliah.
class PenilaianDosen {
  const PenilaianDosen({
    required this.mataKuliahId,
    required this.pertemuan,
    required this.skor,
    required this.dinilaiPada,
    this.komentar = '',
    this.menunggu = false,
    this.galat,
  });

  final int mataKuliahId;

  /// 1..[jumlahPertemuan].
  final int pertemuan;

  /// Kode aspek -> skor 1-5.
  final Map<String, int> skor;
  final String komentar;
  final DateTime dinilaiPada;

  /// True jika perubahan ini masih di antrian dan belum terkirim ke server.
  /// Diisi dari antrian saat dibaca; tidak ikut disimpan/dikirim.
  final bool menunggu;

  /// Alasan penolakan permanen dari server (null = tidak ditolak).
  final String? galat;

  PenilaianDosen denganStatus({required bool menunggu, String? galat}) =>
      PenilaianDosen(
        mataKuliahId: mataKuliahId,
        pertemuan: pertemuan,
        skor: skor,
        komentar: komentar,
        dinilaiPada: dinilaiPada,
        menunggu: menunggu,
        galat: galat,
      );

  double get rataRata => skor.isEmpty
      ? 0
      : skor.values.fold<int>(0, (a, b) => a + b) / skor.length;

  Map<String, Object?> toJson() => {
        'mataKuliahId': mataKuliahId,
        'pertemuan': pertemuan,
        'skor': skor,
        'komentar': komentar,
        'dinilaiPada': dinilaiPada.toIso8601String(),
      };

  factory PenilaianDosen.fromJson(Map<String, dynamic> json) => PenilaianDosen(
        mataKuliahId: json['mataKuliahId'] as int,
        pertemuan: json['pertemuan'] as int,
        skor: Map<String, int>.from(json['skor'] as Map),
        komentar: (json['komentar'] as String?) ?? '',
        dinilaiPada: DateTime.parse(json['dinilaiPada'] as String),
      );
}
