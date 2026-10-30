import 'api_client.dart';
import 'local_store.dart';
import '../models/catatan.dart';

/// Hasil satu putaran sinkronisasi.
class HasilSinkron {
  const HasilSinkron({
    this.offline = false,
    this.terkirim = 0,
    this.ditolak = 0,
    this.pesan,
  });

  /// True jika server tidak terjangkau; sisa antrian ditahan.
  final bool offline;
  final int terkirim;

  /// Perubahan yang ditolak permanen oleh server (mis. data tidak valid).
  final int ditolak;
  final String? pesan;
}

/// Menyinkronkan SQLite lokal dengan MySQL lewat API:
/// 1. kirim antrian (berurutan, idempoten dengan clientId);
/// 2. tarik data server dan satukan ke lokal.
class SinkronService {
  SinkronService(this.api, this.local);

  final ApiClient api;
  final LocalStore local;

  /// Kesalahan 4xx berarti server menolak isi permintaan: mengulang tidak
  /// akan menolong. (408/429 tetap dianggap sementara.)
  static bool _permanen(ApiException e) {
    final kode = e.statusCode;
    return kode != null && kode >= 400 && kode < 500 && kode != 408 && kode != 429;
  }

  Future<HasilSinkron> sinkronkan() async {
    var terkirim = 0;
    var ditolak = 0;
    String? pesan;

    for (final item in await local.antrian()) {
      try {
        if (item.op == OpAntrian.hapus) {
          await api.delete('/api/catatan/klien/${item.clientId}');
        } else {
          final catatan = await local.catatanByClientId(item.clientId);
          if (catatan == null) {
            // Catatan sudah tidak ada di lokal; tidak ada yang dikirim.
            await local.hapusAntrian(item.clientId, item.versi);
            continue;
          }
          final data = await api.put(
            '/api/catatan/klien/${item.clientId}',
            catatan.toRequestBody(),
          );
          final dariServer = Catatan.fromJson(data as Map<String, dynamic>);
          if (dariServer.serverId != null) {
            // Hanya menandai id server; isi catatan lokal tidak ditimpa karena
            // pengguna mungkin mengubahnya saat pengiriman berjalan.
            await local.setServerId(item.clientId, dariServer.serverId!);
          }
        }
        await local.hapusAntrian(item.clientId, item.versi);
        terkirim++;
      } on ApiException catch (e) {
        if (_permanen(e)) {
          await local.catatGagal(item.clientId, item.versi, e.message);
          ditolak++;
          pesan = e.message;
          continue;
        }
        return HasilSinkron(
            offline: true, terkirim: terkirim, ditolak: ditolak, pesan: e.message);
      }
    }

    try {
      final data = await api.get('/api/catatan') as List<dynamic>;
      await _satukan(data
          .map((e) => Catatan.fromJson(e as Map<String, dynamic>))
          .toList());
    } on ApiException catch (e) {
      return HasilSinkron(
          offline: true, terkirim: terkirim, ditolak: ditolak, pesan: e.message);
    }

    return HasilSinkron(terkirim: terkirim, ditolak: ditolak, pesan: pesan);
  }

  /// Menyatukan snapshot server ke lokal. Catatan yang masih punya perubahan
  /// tertunda TIDAK ditimpa (perubahan lokal menang saat dikirim nanti).
  Future<void> _satukan(List<Catatan> dariServer) async {
    // Snapshot lokal diambil setelah data server tiba agar sesegar mungkin.
    final lokal = await local.semuaCatatan();
    final tertunda = (await local.antrian()).map((i) => i.clientId).toSet();
    final lokalByClient = {for (final c in lokal) c.clientId: c};
    final serverByClient = {for (final c in dariServer) c.clientId: c};

    for (final s in dariServer) {
      if (s.clientId.isEmpty || tertunda.contains(s.clientId)) continue;
      await local.simpanCatatan(s.copyWith(id: lokalByClient[s.clientId]?.id));
    }

    // Ada di lokal, sudah pernah terkirim, tidak tertunda, tapi hilang di
    // server = dihapus dari perangkat lain.
    for (final l in lokal) {
      final hilangDiServer = !serverByClient.containsKey(l.clientId);
      if (hilangDiServer && l.serverId != null && !tertunda.contains(l.clientId)) {
        await local.hapusCatatan(l.clientId);
      }
    }
  }
}
