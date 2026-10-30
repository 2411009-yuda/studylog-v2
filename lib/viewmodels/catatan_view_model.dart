import 'package:flutter/foundation.dart';

import '../data/api_client.dart';
import '../data/catatan_repository.dart';
import '../models/catatan.dart';

/// State catatan untuk seluruh layar. UI -> ViewModel -> Repository -> API.
///
/// Setelah setiap perubahan (tambah/ubah/hapus), daftar dimuat ulang dari
/// server sehingga tampilan selalu sama dengan isi database.
class CatatanViewModel extends ChangeNotifier {
  CatatanViewModel(this.repository);

  final CatatanRepository repository;

  List<Catatan> _catatan = [];
  List<Catatan> get catatan => List.unmodifiable(_catatan);

  bool isLoading = false;
  String? error;

  Catatan? byId(int id) {
    for (final item in _catatan) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> muatCatatan() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      _catatan = await repository.semua();
    } catch (e) {
      error = 'Tidak dapat membaca catatan: ${pesanError(e)}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Kesalahan dari server dilempar ke pemanggil agar form dapat
  /// menampilkannya; daftar hanya dimuat ulang jika operasi berhasil.
  Future<void> tambahCatatan(Catatan baru) async {
    await repository.tambah(baru);
    await muatCatatan();
  }

  Future<void> ubahCatatan(Catatan catatan) async {
    await repository.ubah(catatan);
    await muatCatatan();
  }

  Future<void> hapusCatatan(int id) async {
    await repository.hapus(id);
    await muatCatatan();
  }
}
