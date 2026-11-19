import '../models/catatan.dart';
import '../models/course.dart';
import '../models/jadwal.dart';
import '../models/penilaian_dosen.dart';

enum JenisPengingat { penilaian, kelas }

/// Satu hal yang terlewat dan perlu diingatkan.
class Pengingat {
  const Pengingat({
    required this.jenis,
    required this.mataKuliahId,
    required this.mataKuliahKode,
    required this.judul,
    required this.detail,
    this.jumlah = 1,
    this.jadwal,
  });

  final JenisPengingat jenis;
  final int mataKuliahId;
  final String mataKuliahKode;

  /// Nama mata kuliah.
  final String judul;
  final String detail;

  /// Penilaian: banyak pertemuan belum dinilai. Kelas: selalu 1.
  final int jumlah;

  /// Hanya untuk [JenisPengingat.kelas]: jadwal kelas yang belum dicatat.
  final Jadwal? jadwal;

  /// Dipakai membandingkan dua hasil hitung (apakah isinya berubah).
  String get kunci => '${jenis.name}:$mataKuliahId:$detail';
}

DateTime _hari(DateTime t) => DateTime(t.year, t.month, t.day);

DateTime _waktu(DateTime hari, int menit) =>
    DateTime(hari.year, hari.month, hari.day, menit ~/ 60, menit % 60);

/// Tanggal sesi pertama [j] pada atau sesudah [awalSemester].
DateTime _sesiPertama(Jadwal j, DateTime awalSemester) {
  final awal = _hari(awalSemester);
  final geser = (j.hari - awal.weekday) % 7;
  return DateTime(awal.year, awal.month, awal.day + geser);
}

/// Banyak sesi mingguan [j] yang sudah SELESAI pada [sekarang]
/// (maksimal [jumlahPertemuan]).
int sesiSelesai(Jadwal j, DateTime awalSemester, DateTime sekarang) {
  final pertama = _sesiPertama(j, awalSemester);
  var n = 0;
  while (n < jumlahPertemuan) {
    final hari = DateTime(pertama.year, pertama.month, pertama.day + 7 * n);
    if (_waktu(hari, j.menitSelesai).isAfter(sekarang)) break;
    n++;
  }
  return n;
}

String _daftarPertemuan(List<int> nomor) {
  const tampil = 4;
  final awal = nomor.take(tampil).join(', ');
  return nomor.length > tampil ? 'Pertemuan $awal, dst.' : 'Pertemuan $awal';
}

/// Mata kuliah yang pertemuannya sudah berlangsung tetapi belum dinilai.
/// Pertemuan ke-n dianggap sudah berlangsung setelah sesi ke-n selesai.
List<Pengingat> cariPenilaianTerlewat({
  required List<Course> courses,
  required List<Jadwal> jadwal,
  required Set<int> Function(int mataKuliahId) pertemuanDinilai,
  required DateTime awalSemester,
  required DateTime sekarang,
}) {
  final hasil = <Pengingat>[];
  for (final c in courses) {
    var total = 0;
    for (final j in jadwal.where((j) => j.mataKuliahId == c.id)) {
      total += sesiSelesai(j, awalSemester, sekarang);
    }
    if (total > jumlahPertemuan) total = jumlahPertemuan;
    final dinilai = pertemuanDinilai(c.id);
    final kosong = [
      for (var p = 1; p <= total; p++)
        if (!dinilai.contains(p)) p,
    ];
    if (kosong.isEmpty) continue;
    hasil.add(Pengingat(
      jenis: JenisPengingat.penilaian,
      mataKuliahId: c.id,
      mataKuliahKode: c.kode,
      judul: c.nama,
      detail: '${kosong.length} pertemuan belum dinilai '
          '(${_daftarPertemuan(kosong)})',
      jumlah: kosong.length,
    ));
  }
  return hasil;
}

/// Kelas yang sudah selesai dalam [hariMundur] hari terakhir tetapi belum ada
/// catatan untuk mata kuliah itu pada tanggal tersebut. Terbaru lebih dulu.
List<Pengingat> cariKelasTanpaCatatan({
  required List<Course> courses,
  required List<Jadwal> jadwal,
  required List<Catatan> catatan,
  required DateTime awalSemester,
  required DateTime sekarang,
  int hariMundur = 7,
}) {
  final awal = _hari(awalSemester);
  final hariIni = _hari(sekarang);
  final temuan = <({DateTime akhir, Pengingat pengingat})>[];

  for (final j in jadwal) {
    Course? course;
    for (final c in courses) {
      if (c.id == j.mataKuliahId) course = c;
    }
    if (course == null) continue;

    for (var mundur = 0; mundur < hariMundur; mundur++) {
      final tgl =
          DateTime(hariIni.year, hariIni.month, hariIni.day - mundur);
      if (tgl.weekday != j.hari || tgl.isBefore(awal)) continue;
      final akhir = _waktu(tgl, j.menitSelesai);
      if (akhir.isAfter(sekarang)) continue; // belum selesai

      final sudah = catatan.any((c) =>
          c.mataKuliahId == j.mataKuliahId && _hari(c.tanggal) == tgl);
      if (sudah) continue;

      temuan.add((
        akhir: akhir,
        pengingat: Pengingat(
          jenis: JenisPengingat.kelas,
          mataKuliahId: course.id,
          mataKuliahKode: course.kode,
          judul: course.nama,
          detail: 'Kelas ${namaHari(j.hari)} ${tgl.day}/${tgl.month} '
              'belum dicatat',
          jadwal: j,
        ),
      ));
    }
  }
  temuan.sort((a, b) => b.akhir.compareTo(a.akhir));
  return [for (final t in temuan) t.pengingat];
}

/// Teks untuk notifikasi sistem.
({String judul, String isi}) ringkasanPengingat(List<Pengingat> daftar) {
  var penilaian = 0;
  var kelas = 0;
  for (final p in daftar) {
    if (p.jenis == JenisPengingat.penilaian) {
      penilaian += p.jumlah;
    } else {
      kelas += p.jumlah;
    }
  }
  final bagian = [
    if (penilaian > 0) '$penilaian pertemuan belum dinilai',
    if (kelas > 0) '$kelas kelas belum dicatat',
  ];
  return (
    judul: 'StudyLog: ada yang terlewat',
    isi: bagian.join(' · '),
  );
}

/// Contoh: 19/11/2026 pukul 14:05
String labelTanggalWaktu(DateTime t) {
  String dua(int n) => n.toString().padLeft(2, '0');
  return '${t.day}/${t.month}/${t.year} pukul ${dua(t.hour)}:${dua(t.minute)}';
}
