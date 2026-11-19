import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/pengingat_config.dart';
import '../services/notifikasi_service.dart';
import '../utils/pengingat_utils.dart';
import 'catatan_view_model.dart';
import 'mata_kuliah_view_model.dart';
import 'penilaian_view_model.dart';

/// Menghitung penilaian dosen dan catatan kelas yang terlewat, lalu
/// menjadwalkan notifikasi harian. Dihitung ulang setiap data mata kuliah,
/// penilaian, atau catatan berubah, dan saat aplikasi kembali dibuka
/// ([perbarui]) karena waktu berjalan.
class PengingatViewModel extends ChangeNotifier {
  PengingatViewModel({
    required this.mataKuliah,
    required this.penilaian,
    required this.catatan,
    required this.notifikasi,
    DateTime? awalSemester,
    this.jam = jamPengingatBawaan,
    this.menit = menitPengingatBawaan,
    DateTime Function()? clock,
  })  : awalSemester = awalSemester ?? awalSemesterBawaan,
        _clock = clock ?? DateTime.now;

  final MataKuliahViewModel mataKuliah;
  final PenilaianViewModel penilaian;
  final CatatanViewModel catatan;
  final NotifikasiService notifikasi;
  final DateTime awalSemester;
  final int jam;
  final int menit;
  final DateTime Function() _clock;

  List<Pengingat> _daftar = const [];
  String? _kunciTerakhir;
  bool _dipasang = false;

  List<Pengingat> get daftar => _daftar;
  bool get adaYangTerlewat => _daftar.isNotEmpty;

  /// Dipanggil sekali saat aplikasi dibuka.
  void mulai() {
    if (_dipasang) return;
    _dipasang = true;
    mataKuliah.addListener(perbarui);
    penilaian.addListener(perbarui);
    catatan.addListener(perbarui);
    perbarui();
  }

  @override
  void dispose() {
    if (_dipasang) {
      mataKuliah.removeListener(perbarui);
      penilaian.removeListener(perbarui);
      catatan.removeListener(perbarui);
    }
    super.dispose();
  }

  void perbarui() {
    // Tanpa daftar mata kuliah (belum dimuat / gagal) tidak ada yang bisa
    // dihitung; jangan membatalkan pengingat yang sudah terjadwal.
    if (mataKuliah.courses.isEmpty || mataKuliah.jadwal.isEmpty) return;

    final sekarang = _clock();
    final baru = [
      ...cariPenilaianTerlewat(
        courses: mataKuliah.courses,
        jadwal: mataKuliah.jadwal,
        pertemuanDinilai: (id) =>
            penilaian.daftarUntuk(id).map((p) => p.pertemuan).toSet(),
        awalSemester: awalSemester,
        sekarang: sekarang,
      ),
      ...cariKelasTanpaCatatan(
        courses: mataKuliah.courses,
        jadwal: mataKuliah.jadwal,
        catatan: catatan.catatan,
        awalSemester: awalSemester,
        sekarang: sekarang,
        hariMundur: hariMundurKelas,
      ),
    ];

    final kunci = baru.map((p) => p.kunci).join('|');
    if (kunci == _kunciTerakhir) return;
    _kunciTerakhir = kunci;
    _daftar = baru;
    notifyListeners();
    unawaited(_aturNotifikasi());
  }

  /// Menampilkan notifikasi uji sekarang juga. False = tidak dapat tampil
  /// (mis. izin notifikasi belum diberikan).
  Future<bool> ujiNotifikasi() {
    final waktu = labelTanggalWaktu(_clock());
    return notifikasi.tampilkanSekarang(
      judul: 'Uji notifikasi StudyLog',
      isi: 'Pengujian notifikasi dilakukan pada $waktu',
    );
  }

  Future<void> _aturNotifikasi() async {
    if (_daftar.isEmpty) {
      await notifikasi.batalkanHarian();
      return;
    }
    final teks = ringkasanPengingat(_daftar);
    await notifikasi.jadwalkanHarian(
      judul: teks.judul,
      isi: teks.isi,
      jam: jam,
      menit: menit,
    );
  }
}
