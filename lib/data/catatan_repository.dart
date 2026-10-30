import '../models/catatan.dart';
import '../utils/uuid.dart';
import 'local_store.dart';

/// Akses data catatan, OFFLINE-FIRST: membaca dan menulis selalu ke SQLite
/// lokal, lalu setiap perubahan dicatat ke antrian untuk dikirim ke server
/// oleh [SinkronService]. Tidak pernah menunggu jaringan.
class CatatanRepository {
  CatatanRepository(this.local, {String Function()? buatId})
      : _buatId = buatId ?? buatUuidV4;

  final LocalStore local;
  final String Function() _buatId;

  Future<List<Catatan>> semua() => local.semuaCatatan();

  Future<List<ItemAntrian>> antrian() => local.antrian();

  /// Catatan baru: diberi clientId, disimpan lokal, masuk antrian.
  Future<Catatan> tambah(Catatan catatan) async {
    final baru = catatan.copyWith(clientId: _buatId());
    final tersimpan = await local.simpanCatatan(baru);
    await local.setAntrian(tersimpan.clientId, OpAntrian.upsert);
    return tersimpan;
  }

  /// Mengubah catatan yang sudah ada. Jika catatan ini belum pernah terkirim,
  /// entri antriannya hanya diperbarui (tidak ada dua kiriman terpisah).
  Future<Catatan> ubah(Catatan catatan) async {
    if (catatan.id == null || catatan.clientId.isEmpty) {
      throw ArgumentError('ID catatan tidak boleh kosong');
    }
    final tersimpan = await local.simpanCatatan(catatan);
    await local.setAntrian(catatan.clientId, OpAntrian.upsert);
    return tersimpan;
  }

  /// Menghapus di perangkat sekarang juga; penghapusan di server menyusul.
  Future<void> hapus(int id) async {
    final catatan = await local.catatanById(id);
    if (catatan == null) return;
    await local.hapusCatatan(catatan.clientId);
    await local.setAntrian(catatan.clientId, OpAntrian.hapus);
  }
}
