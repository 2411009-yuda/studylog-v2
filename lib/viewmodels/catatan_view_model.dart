import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/catatan_repository.dart';
import '../data/sinkron_service.dart';
import '../models/catatan.dart';
import '../utils/urutan_catatan.dart';

/// Status hubungan dengan server pada sinkronisasi terakhir.
enum StatusSinkron { belumDiketahui, menyinkronkan, online, offline }

/// State catatan untuk seluruh layar. UI -> ViewModel -> Repository -> SQLite,
/// dan SinkronService yang menyamakan SQLite dengan MySQL di latar belakang.
///
/// Daftar selalu dibaca dari penyimpanan lokal, sehingga cepat dan tetap
/// berfungsi tanpa koneksi.
class CatatanViewModel extends ChangeNotifier {
  CatatanViewModel(this.repository, this.sinkron);

  final CatatanRepository repository;
  final SinkronService sinkron;

  /// Selalu tersimpan dalam urutan [urutan] yang dipilih pengguna.
  List<Catatan> _catatan = [];
  List<Catatan> get catatan => List.unmodifiable(_catatan);

  UrutanCatatan _urutan = UrutanCatatan.terbaru;
  UrutanCatatan get urutan => _urutan;

  bool isLoading = false;
  String? error;

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

  /// Urutan dilakukan di aplikasi, jadi tetap berlaku setelah data dimuat ulang.
  void ubahUrutan(UrutanCatatan baru) {
    if (baru == _urutan) return;
    _urutan = baru;
    _catatan = urutkanCatatan(_catatan, _urutan);
    notifyListeners();
  }

  Catatan? byId(int id) {
    for (final item in _catatan) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Dipanggil saat aplikasi dibuka: tampilkan data lokal dulu, lalu sinkron.
  Future<void> mulai() async {
    await muatCatatan();
    await sinkronkan();
  }

  Future<void> _bacaLokal() async {
    _catatan = urutkanCatatan(await repository.semua(), _urutan);
    final antrian = await repository.antrian();
    tertunda = antrian.length;
    ditolak = antrian.where((i) => i.error != null).length;
  }

  Future<void> muatCatatan() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _bacaLokal();
    } catch (e) {
      error = 'Tidak dapat membaca catatan: ${pesanError(e)}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---- Perubahan: ditulis ke lokal dulu, server menyusul ----

  Future<void> tambahCatatan(Catatan baru) async {
    await repository.tambah(baru);
    await _setelahPerubahanLokal();
  }

  Future<void> ubahCatatan(Catatan catatan) async {
    await repository.ubah(catatan);
    await _setelahPerubahanLokal();
  }

  Future<void> hapusCatatan(int id) async {
    await repository.hapus(id);
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
        final HasilSinkron hasil = await sinkron.sinkronkan();
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
