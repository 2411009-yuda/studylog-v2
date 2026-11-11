import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/catatan_repository.dart';
import '../data/sinkron_service.dart';
import '../models/catatan.dart';
import '../utils/cari_catatan.dart';
import '../utils/kelompok_catatan.dart';
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

  String _kueri = '';

  /// Kata kunci pencarian yang sedang aktif ('' = tidak mencari).
  String get kueri => _kueri;

  bool get sedangMencari => _kueri.trim().isNotEmpty;

  /// Catatan yang cocok dengan [kueri], tetap dalam urutan [urutan].
  /// Dihitung dari data lokal, jadi pencarian bekerja tanpa koneksi.
  List<Catatan> get hasilCari => cariCatatan(_catatan, _kueri);

  int? _filterMataKuliahId;

  /// Id mata kuliah yang dipilih sebagai filter (null = semua mata kuliah).
  int? get filterMataKuliahId => _filterMataKuliahId;

  bool _hanyaFavorit = false;

  /// True jika hanya catatan favorit yang ditampilkan.
  bool get hanyaFavorit => _hanyaFavorit;

  int get jumlahFavorit => _catatan.where((c) => c.favorit).length;

  bool _kelompokkan = false;

  /// True jika daftar ditampilkan per kelompok mata kuliah.
  bool get kelompokkan => _kelompokkan;

  /// Mata kuliah yang punya catatan, beserta jumlahnya (untuk chip filter).
  /// Selalu dihitung dari semua catatan agar jumlahnya tidak ikut berubah
  /// saat mencari.
  List<RingkasMataKuliah> get daftarMataKuliah => ringkasMataKuliah(_catatan);

  /// True jika pencarian atau filter mata kuliah sedang aktif.
  bool get sedangMenyaring =>
      sedangMencari || _filterMataKuliahId != null || _hanyaFavorit;

  /// Yang benar-benar ditampilkan: pencarian + filter mata kuliah,
  /// dalam urutan [urutan].
  List<Catatan> get catatanTampil {
    final hasil = filterMataKuliah(hasilCari, _filterMataKuliahId);
    return _hanyaFavorit ? hasil.where((c) => c.favorit).toList() : hasil;
  }

  /// [catatanTampil] dikelompokkan per mata kuliah.
  List<KelompokCatatan> get kelompokTampil =>
      kelompokkanPerMataKuliah(catatanTampil);

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

  /// Pencarian hanya menyaring tampilan; data dan antrian sinkron tidak berubah.
  void ubahKueri(String baru) {
    if (baru == _kueri) return;
    _kueri = baru;
    notifyListeners();
  }

  void ubahFilterMataKuliah(int? id) {
    if (id == _filterMataKuliahId) return;
    _filterMataKuliahId = id;
    notifyListeners();
  }

  void ubahHanyaFavorit(bool nilai) {
    if (nilai == _hanyaFavorit) return;
    _hanyaFavorit = nilai;
    notifyListeners();
  }

  /// Menandai/melepas favorit. Hanya menulis ke penyimpanan lokal; tidak ada
  /// sinkronisasi karena favorit tidak dikirim ke server.
  Future<void> setFavorit(int id, bool nilai) async {
    await repository.setFavorit(id, nilai);
    await _bacaLokal();
    notifyListeners();
  }

  void ubahKelompokkan(bool nilai) {
    if (nilai == _kelompokkan) return;
    _kelompokkan = nilai;
    notifyListeners();
  }

  /// Menghapus pencarian dan semua filter (mata kuliah, favorit) sekaligus.
  void resetPenyaring() {
    if (!sedangMenyaring && _kueri.isEmpty) return;
    _kueri = '';
    _filterMataKuliahId = null;
    _hanyaFavorit = false;
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
    // Filter dilepas jika mata kuliahnya sudah tidak punya catatan
    // (dihapus, atau hilang setelah sinkron).
    if (_filterMataKuliahId != null &&
        !_catatan.any((c) => c.mataKuliahId == _filterMataKuliahId)) {
      _filterMataKuliahId = null;
    }
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
