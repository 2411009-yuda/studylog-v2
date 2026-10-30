import '../models/catatan.dart';

/// Jenis perubahan yang menunggu dikirim ke server.
enum OpAntrian { upsert, hapus }

/// Satu perubahan dalam antrian (outbox). Hanya ada SATU entri per catatan:
/// perubahan baru pada catatan yang sama menggantikan yang lama.
class ItemAntrian {
  const ItemAntrian({
    required this.clientId,
    required this.op,
    required this.versi,
    this.percobaan = 0,
    this.error,
  });

  final String clientId;
  final OpAntrian op;

  /// Naik setiap kali entri diganti. Dipakai agar pengiriman yang selesai
  /// tidak menghapus perubahan lebih baru yang dibuat saat pengiriman berjalan.
  final int versi;
  final int percobaan;

  /// Alasan penolakan permanen dari server (null = belum pernah ditolak).
  final String? error;
}

/// Penyimpanan lokal di perangkat: salinan catatan, antrian, dan cache.
/// Implementasi nyata: SqliteLocalStore. Pengujian memakai versi memori.
abstract class LocalStore {
  /// Semua catatan lokal; [Catatan.menunggu] terisi dari antrian.
  Future<List<Catatan>> semuaCatatan();
  Future<Catatan?> catatanById(int id);
  Future<Catatan?> catatanByClientId(String clientId);

  /// Menyimpan berdasarkan clientId: ubah jika ada, sisip jika belum.
  /// Mengembalikan catatan dengan id lokal.
  Future<Catatan> simpanCatatan(Catatan catatan);
  Future<void> hapusCatatan(String clientId);
  Future<void> setServerId(String clientId, int serverId);

  /// Antrian, tertua dulu.
  Future<List<ItemAntrian>> antrian();

  /// Menaruh/menggantikan entri antrian catatan ini (versi naik).
  Future<void> setAntrian(String clientId, OpAntrian op);

  /// Menghapus entri hanya jika [versi] masih sama.
  Future<void> hapusAntrian(String clientId, int versi);

  /// Menandai entri ditolak server (hanya jika [versi] masih sama).
  Future<void> catatGagal(String clientId, int versi, String error);

  /// Cache sederhana (mis. daftar mata kuliah & jadwal untuk mode offline).
  Future<String?> bacaCache(String kunci);
  Future<void> tulisCache(String kunci, String nilai);
}
