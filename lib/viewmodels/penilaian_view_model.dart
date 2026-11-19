import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/penilaian_repository.dart';
import '../data/sinkron_service.dart' show HasilSinkron;
import '../models/penilaian_dosen.dart';
import 'catatan_view_model.dart' show StatusSinkron;

/// State penilaian dosen untuk seluruh mata kuliah. Offline-first: daftar
/// selalu dibaca dari penyimpanan lokal; server disamakan di latar belakang.
class PenilaianViewModel extends ChangeNotifier {
  PenilaianViewModel(this.repository);

  final PenilaianRepository repository;

  List<PenilaianDosen> _data = [];

  // ---- Status sinkronisasi ----
  StatusSinkron status = StatusSinkron.belumDiketahui;

  /// Jumlah perubahan di antrian (belum terkirim, termasuk yang ditolak).
  int tertunda = 0;

  /// Dari [tertunda], berapa yang ditolak permanen oleh server.
  int ditolak = 0;
  String? pesanSinkron;
  DateTime? terakhirSinkron;

  Future<void>? _sedangJalan;
  bool _ulangi = false;

  /// Dipanggil saat aplikasi dibuka: tampilkan data lokal dulu, lalu sinkron.
  Future<void> mulai() async {
    await _bacaLokal();
    notifyListeners();
    await sinkronkan();
  }

  Future<void> _bacaLokal() async {
    _data = await repository.semua();
    tertunda = repository.tertunda;
    ditolak = repository.ditolak;
  }

  PenilaianDosen? untuk(int mataKuliahId, int pertemuan) {
    for (final p in _data) {
      if (p.mataKuliahId == mataKuliahId && p.pertemuan == pertemuan) return p;
    }
    return null;
  }

  List<PenilaianDosen> daftarUntuk(int mataKuliahId) => _data
      .where((p) => p.mataKuliahId == mataKuliahId)
      .toList()
    ..sort((a, b) => a.pertemuan.compareTo(b.pertemuan));

  int jumlahTerisi(int mataKuliahId) => daftarUntuk(mataKuliahId).length;

  /// Rata-rata dari rata-rata tiap pertemuan; null jika belum ada penilaian.
  double? rataRataMatkul(int mataKuliahId) {
    final daftar = daftarUntuk(mataKuliahId);
    if (daftar.isEmpty) return null;
    return daftar.fold<double>(0, (a, p) => a + p.rataRata) / daftar.length;
  }

  /// Semua aspek wajib dinilai (skor 1-5).
  String? validateSkor(Map<String, int> skor) {
    for (final a in aspekPenilaian) {
      final nilai = skor[a.kode];
      if (nilai == null || nilai < skorMin || nilai > skorMaks) {
        return 'Semua aspek wajib dinilai';
      }
    }
    return null;
  }

  // ---- Perubahan: ditulis ke lokal dulu, server menyusul ----

  /// Menyimpan penilaian di perangkat (tidak menunggu jaringan); pertemuan
  /// yang sama diganti.
  Future<void> simpan({
    required int mataKuliahId,
    required int pertemuan,
    required Map<String, int> skor,
    String komentar = '',
  }) async {
    if (validateSkor(skor) != null) {
      throw ArgumentError('Semua aspek wajib dinilai');
    }
    await repository.simpan(
      mataKuliahId: mataKuliahId,
      pertemuan: pertemuan,
      skor: skor,
      komentar: komentar,
    );
    await _setelahPerubahanLokal();
  }

  Future<void> hapus(int mataKuliahId, int pertemuan) async {
    await repository.hapus(mataKuliahId, pertemuan);
    await _setelahPerubahanLokal();
  }

  Future<void> _setelahPerubahanLokal() async {
    await _bacaLokal();
    notifyListeners();
    // Kirim di latar belakang; pemanggil tidak menunggu jaringan.
    unawaited(sinkronkan());
  }

  // ---- Sinkronisasi ----

  /// Menjalankan sinkronisasi. Jika sudah berjalan, putaran berikutnya
  /// dijadwalkan dan Future yang sama dikembalikan.
  Future<void> sinkronkan() {
    final berjalan = _sedangJalan;
    if (berjalan != null) {
      _ulangi = true;
      return berjalan;
    }
    return _sedangJalan = _jalankan().whenComplete(() => _sedangJalan = null);
  }

  Future<void> _jalankan() async {
    do {
      _ulangi = false;
      status = StatusSinkron.menyinkronkan;
      notifyListeners();
      try {
        final HasilSinkron hasil = await repository.sinkronkan();
        status = hasil.offline ? StatusSinkron.offline : StatusSinkron.online;
        pesanSinkron = hasil.pesan;
        if (!hasil.offline) terakhirSinkron = DateTime.now();
        await _bacaLokal();
      } catch (e) {
        status = StatusSinkron.offline;
        pesanSinkron = pesanError(e);
      }
      notifyListeners();
    } while (_ulangi);
  }
}
