import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/mata_kuliah_repository.dart';
import '../models/course.dart';
import '../models/jadwal.dart';
import '../utils/jadwal_utils.dart';

/// State mata kuliah + jadwal (dari database lewat API).
class MataKuliahViewModel extends ChangeNotifier {
  MataKuliahViewModel(this.repository, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final MataKuliahRepository repository;
  final DateTime Function() _clock;

  List<Course> _courses = [];
  List<Jadwal> _jadwal = [];

  List<Course> get courses => List.unmodifiable(_courses);
  List<Jadwal> get jadwal => List.unmodifiable(_jadwal);

  bool isLoading = false;
  String? error;

  int get totalSks => _courses.fold(0, (sum, c) => sum + c.sks);

  Future<void> muat() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final hasil = await Future.wait([
        repository.semuaMataKuliah(),
        repository.semuaJadwal(),
      ]);
      _courses = hasil[0] as List<Course>;
      _jadwal = hasil[1] as List<Jadwal>;
    } catch (e) {
      error = 'Tidak dapat memuat mata kuliah: ${pesanError(e)}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Course? courseById(int id) {
    for (final c in _courses) {
      if (c.id == id) return c;
    }
    return null;
  }

  Course? courseByKode(String kode) {
    for (final c in _courses) {
      if (c.kode == kode) return c;
    }
    return null;
  }

  List<Jadwal> jadwalUntuk(int mataKuliahId) => _jadwal
      .where((j) => j.mataKuliahId == mataKuliahId)
      .toList()
    ..sort((a, b) => a.hari != b.hari
        ? a.hari.compareTo(b.hari)
        : a.menitMulai.compareTo(b.menitMulai));

  /// Jadwal yang dipakai tombol + untuk mengisi mata kuliah otomatis.
  Jadwal? jadwalUntukCatatanBaru() =>
      cariJadwalUntukCatatan(_jadwal, _clock());

  /// Kelas yang sedang berlangsung / berikutnya (untuk kartu Beranda).
  JadwalTerdekat? jadwalTerdekat() => cariJadwalTerdekat(_jadwal, _clock());
}
