import 'dart:async';
import 'dart:convert';

import 'package:profil_mahasiswa/data/realtime_service.dart';

import 'fake_server.dart';

/// Satu sambungan WebSocket tiruan.
class FakeSambungan implements RealtimeConnection {
  final StreamController<dynamic> controller = StreamController<dynamic>();
  bool tertutup = false;

  @override
  Stream<dynamic> get pesan => controller.stream;

  @override
  Future<void> tutup() async {
    tertutup = true;
    if (!controller.isClosed) await controller.close();
  }
}

/// WebSocket tiruan: tes dapat "mengirim kabar dari server", memutus
/// sambungan, dan membuat sambungan gagal.
class FakeRealtime {
  final List<FakeSambungan> sambungan = [];

  /// Jika true, setiap upaya menyambung gagal.
  bool gagalSambung = false;

  /// Jumlah upaya menyambung (berhasil maupun gagal).
  int percobaan = 0;

  Future<RealtimeConnection> penyambung(Uri uri) async {
    percobaan++;
    if (gagalSambung) throw StateError('tidak dapat tersambung');
    final s = FakeSambungan();
    sambungan.add(s);
    return s;
  }

  int get jumlahTerbuka => sambungan.where((s) => !s.tertutup).length;

  FakeSambungan? get _terbuka {
    for (final s in sambungan.reversed) {
      if (!s.tertutup && !s.controller.isClosed) return s;
    }
    return null;
  }

  /// Server mengirim [event] sebagai JSON.
  void kirim(Map<String, Object?> event) =>
      _terbuka?.controller.add(jsonEncode(event));

  /// Server mengirim teks mentah (mis. pesan rusak).
  void kirimMentah(Object? data) => _terbuka?.controller.add(data);

  /// Server menutup sambungan (mis. restart, jaringan putus).
  void putus() => _terbuka?.controller.close();

  /// Setiap perubahan pada [server] disiarkan lewat sambungan ini.
  void hubungkan(FakeServer server) => server.onSiarkan = kirim;
}
