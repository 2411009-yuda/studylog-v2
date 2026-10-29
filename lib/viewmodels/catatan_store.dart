import 'package:flutter/foundation.dart';

import '../models/catatan.dart';

/// State catatan lintas layar (Praktikum 2).
///
/// Data hanya berada di RAM: bertahan saat pindah layar, rotasi, dan Hot
/// Reload, tetapi HILANG saat aplikasi dihentikan penuh. Penyimpanan
/// permanen dikerjakan pada Praktikum 3.
class CatatanStore extends ChangeNotifier {
  final List<Catatan> _data = [];
  int _idBerikut = 1;

  /// Terbaru di atas. Tidak dapat dimodifikasi dari luar.
  List<Catatan> get data => List.unmodifiable(_data);

  int get jumlah => _data.length;

  Catatan? byId(int id) {
    for (final item in _data) {
      if (item.id == id) return item;
    }
    return null;
  }

  Catatan tambah({
    required String mataKuliah,
    required String topik,
    required String judul,
    required String isi,
    DateTime? tanggal,
  }) {
    final baru = Catatan(
      id: _idBerikut++,
      mataKuliah: mataKuliah.trim(),
      topik: topik.trim(),
      judul: judul.trim(),
      isi: isi.trim(),
      tanggal: tanggal ?? DateTime.now(),
    );
    _data.insert(0, baru);
    notifyListeners();
    return baru;
  }
}
