import 'package:profil_mahasiswa/data/local_store.dart';
import 'package:profil_mahasiswa/models/catatan.dart';

class _Antri {
  _Antri(this.clientId, this.op, this.urut);

  final String clientId;
  OpAntrian op;
  int versi = 1;
  int percobaan = 0;
  String? error;
  final int urut;
}

/// Pengganti SqliteLocalStore untuk pengujian (SQLite membutuhkan platform
/// Android/iOS). Perilakunya mengikuti kontrak LocalStore; implementasi
/// SQLite diuji langsung di perangkat.
class InMemoryLocalStore implements LocalStore {
  final List<Catatan> _rows = [];
  final Map<String, _Antri> _antrian = {};
  final Map<String, String> _cache = {};
  int _idBerikut = 1;
  int _urutBerikut = 1;

  Catatan _tandai(Catatan c) =>
      c.copyWith(menunggu: _antrian.containsKey(c.clientId));

  @override
  Future<List<Catatan>> semuaCatatan() async {
    final hasil = _rows.map(_tandai).toList()
      ..sort((a, b) {
        final t = b.tanggal.compareTo(a.tanggal);
        return t != 0 ? t : b.id!.compareTo(a.id!);
      });
    return hasil;
  }

  @override
  Future<Catatan?> catatanById(int id) async {
    for (final c in _rows) {
      if (c.id == id) return _tandai(c);
    }
    return null;
  }

  @override
  Future<Catatan?> catatanByClientId(String clientId) async {
    for (final c in _rows) {
      if (c.clientId == clientId) return _tandai(c);
    }
    return null;
  }

  @override
  Future<Catatan> simpanCatatan(Catatan catatan) async {
    final index = _rows.indexWhere((c) => c.clientId == catatan.clientId);
    if (index >= 0) {
      final tersimpan =
          catatan.copyWith(id: _rows[index].id, menunggu: false);
      _rows[index] = tersimpan;
      return _tandai(tersimpan);
    }
    final tersimpan = catatan.copyWith(id: _idBerikut++, menunggu: false);
    _rows.add(tersimpan);
    return _tandai(tersimpan);
  }

  @override
  Future<void> hapusCatatan(String clientId) async {
    _rows.removeWhere((c) => c.clientId == clientId);
  }

  @override
  Future<void> setServerId(String clientId, int serverId) async {
    final index = _rows.indexWhere((c) => c.clientId == clientId);
    if (index >= 0) _rows[index] = _rows[index].copyWith(serverId: serverId);
  }

  @override
  Future<List<ItemAntrian>> antrian() async {
    final daftar = _antrian.values.toList()
      ..sort((a, b) => a.urut.compareTo(b.urut));
    return daftar
        .map((a) => ItemAntrian(
              clientId: a.clientId,
              op: a.op,
              versi: a.versi,
              percobaan: a.percobaan,
              error: a.error,
            ))
        .toList();
  }

  @override
  Future<void> setAntrian(String clientId, OpAntrian op) async {
    final ada = _antrian[clientId];
    if (ada == null) {
      _antrian[clientId] = _Antri(clientId, op, _urutBerikut++);
    } else {
      ada
        ..op = op
        ..versi += 1
        ..percobaan = 0
        ..error = null;
    }
  }

  @override
  Future<void> hapusAntrian(String clientId, int versi) async {
    final ada = _antrian[clientId];
    if (ada != null && ada.versi == versi) _antrian.remove(clientId);
  }

  @override
  Future<void> catatGagal(String clientId, int versi, String error) async {
    final ada = _antrian[clientId];
    if (ada != null && ada.versi == versi) {
      ada
        ..percobaan += 1
        ..error = error;
    }
  }

  @override
  Future<String?> bacaCache(String kunci) async => _cache[kunci];

  @override
  Future<void> tulisCache(String kunci, String nilai) async =>
      _cache[kunci] = nilai;
}
