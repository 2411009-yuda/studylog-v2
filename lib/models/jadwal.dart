const _namaHari = {
  1: 'Senin',
  2: 'Selasa',
  3: 'Rabu',
  4: 'Kamis',
  5: 'Jumat',
  6: 'Sabtu',
  7: 'Minggu',
};

String namaHari(int hari) => _namaHari[hari] ?? '-';

int _menit(String jam) {
  final bagian = jam.split(':');
  return int.parse(bagian[0]) * 60 + int.parse(bagian[1]);
}

/// Satu sesi kuliah mingguan (tabel jadwal). [hari] mengikuti
/// DateTime.weekday: 1 = Senin ... 7 = Minggu.
class Jadwal {
  const Jadwal({
    required this.id,
    required this.mataKuliahId,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.kelas,
    required this.ruang,
  });

  final int id;
  final int mataKuliahId;
  final int hari;
  final String jamMulai; // 'HH:MM'
  final String jamSelesai; // 'HH:MM'
  final String kelas;
  final String ruang;

  int get menitMulai => _menit(jamMulai);
  int get menitSelesai => _menit(jamSelesai);

  /// Contoh: Jumat 20:30–22:00
  String get label => '${namaHari(hari)} $jamMulai–$jamSelesai';

  factory Jadwal.fromJson(Map<String, dynamic> json) => Jadwal(
        id: json['id'] as int,
        mataKuliahId: json['mataKuliahId'] as int,
        hari: json['hari'] as int,
        jamMulai: json['jamMulai'] as String,
        jamSelesai: json['jamSelesai'] as String,
        kelas: (json['kelas'] as String?) ?? '',
        ruang: (json['ruang'] as String?) ?? '',
      );
}
