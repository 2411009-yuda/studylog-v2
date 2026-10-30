import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';

/// Keadaan hubungan WebSocket dengan server.
enum StatusRealtime { terputus, menyambung, tersambung }

/// Satu sambungan WebSocket yang terbuka. Dibuat sebagai antarmuka agar
/// dapat diganti tiruan pada pengujian.
abstract class RealtimeConnection {
  Stream<dynamic> get pesan;
  Future<void> tutup();
}

typedef Penyambung = Future<RealtimeConnection> Function(Uri uri);

/// Sambungan nyata memakai web_socket_channel (dart:io, Android).
class SambunganWebSocket implements RealtimeConnection {
  SambunganWebSocket._(this._channel);

  final IOWebSocketChannel _channel;

  static Future<RealtimeConnection> sambung(Uri uri) async {
    // pingInterval: koneksi yang mati diam-diam (sinyal hilang) terdeteksi
    // dari tidak adanya balasan ping, lalu stream ditutup.
    final channel = IOWebSocketChannel.connect(
      uri,
      pingInterval: const Duration(seconds: 20),
    );
    try {
      await channel.ready.timeout(const Duration(seconds: 8));
    } catch (_) {
      await channel.sink.close();
      rethrow;
    }
    return SambunganWebSocket._(channel);
  }

  @override
  Stream<dynamic> get pesan => _channel.stream;

  @override
  Future<void> tutup() => _channel.sink.close();
}

/// Real-time: mendengarkan kabar "ada catatan berubah" dari server.
///
/// Pesan server hanya pemberitahuan. Layanan ini TIDAK membaca isinya
/// sebagai data; ia memanggil [onPerubahan] agar aplikasi menarik data lewat
/// sinkronisasi biasa. Karena itu kabar yang terlewat tidak berbahaya:
/// setiap kali tersambung (termasuk sambung ulang) [onTersambung] dipanggil
/// untuk menarik ulang semuanya.
///
/// Putus koneksi ditangani dengan sambung ulang bertahap (1s, 2s, 4s, ...
/// maksimum [jedaMaks]).
class RealtimeService extends ChangeNotifier {
  RealtimeService({
    this.uri,
    Penyambung? penyambung,
    this.debounce = const Duration(milliseconds: 250),
    this.jedaAwal = const Duration(seconds: 1),
    this.jedaMaks = const Duration(seconds: 30),
  }) : _penyambung = penyambung ?? SambunganWebSocket.sambung;

  /// Alamat WebSocket. Null = real-time dinonaktifkan.
  final Uri? uri;

  /// Beberapa kabar beruntun digabung menjadi satu penarikan data.
  /// Duration.zero = tanpa penundaan.
  final Duration debounce;
  final Duration jedaAwal;
  final Duration jedaMaks;

  /// Dipasang oleh pemakai layanan (lihat SinkronPemicu).
  void Function()? onPerubahan;
  void Function()? onTersambung;

  final Penyambung _penyambung;

  StatusRealtime _status = StatusRealtime.terputus;
  StatusRealtime get status => _status;
  bool get tersambung => _status == StatusRealtime.tersambung;

  /// True jika layanan sedang dijalankan (dan punya alamat).
  bool get aktif => _aktif;

  bool _aktif = false;
  bool _dibuang = false;
  int _percobaan = 0;
  int _generasi = 0; // membatalkan hasil sambungan yang sudah usang
  RealtimeConnection? _koneksi;
  StreamSubscription<dynamic>? _langganan;
  Timer? _timerUlang;
  Timer? _timerDebounce;

  /// Jeda sebelum percobaan sambung ke-[percobaan] (mulai dari 0).
  @visibleForTesting
  static Duration jeda(int percobaan, Duration awal, Duration maks) {
    final hasil = awal * (1 << min(percobaan, 16));
    return hasil > maks ? maks : hasil;
  }

  void mulai() {
    if (uri == null || _aktif || _dibuang) return;
    _aktif = true;
    _percobaan = 0;
    unawaited(_sambung());
  }

  Future<void> berhenti() async {
    if (!_aktif) return;
    _aktif = false;
    _generasi++;
    _timerUlang?.cancel();
    _timerDebounce?.cancel();
    await _lepas();
    _ubah(StatusRealtime.terputus);
  }

  Future<void> _lepas() async {
    final langganan = _langganan;
    final koneksi = _koneksi;
    _langganan = null;
    _koneksi = null;
    await langganan?.cancel();
    try {
      await koneksi?.tutup();
    } catch (_) {}
  }

  Future<void> _sambung() async {
    final generasi = ++_generasi;
    _ubah(StatusRealtime.menyambung);

    final RealtimeConnection koneksi;
    try {
      koneksi = await _penyambung(uri!);
    } catch (_) {
      if (_aktif && generasi == _generasi) _jadwalkanUlang();
      return;
    }

    if (!_aktif || generasi != _generasi) {
      try {
        await koneksi.tutup();
      } catch (_) {}
      return;
    }

    _koneksi = koneksi;
    _percobaan = 0;
    _langganan = koneksi.pesan.listen(
      _terima,
      onDone: () => _terputus(generasi),
      onError: (_) => _terputus(generasi),
      cancelOnError: true,
    );
    _ubah(StatusRealtime.tersambung);
    // Sambung/sambung ulang: tarik data karena kabar sebelumnya mungkin terlewat.
    onTersambung?.call();
  }

  void _terputus(int generasi) {
    if (!_aktif || generasi != _generasi) return;
    _langganan?.cancel();
    _langganan = null;
    _koneksi = null;
    _jadwalkanUlang();
  }

  void _jadwalkanUlang() {
    _ubah(StatusRealtime.terputus);
    _timerUlang?.cancel();
    final tunda = jeda(_percobaan, jedaAwal, jedaMaks);
    _percobaan++;
    _timerUlang = Timer(tunda, () {
      if (_aktif) unawaited(_sambung());
    });
  }

  void _terima(dynamic data) {
    if (data is! String) return;
    try {
      final json = jsonDecode(data);
      if (json is Map && json['tipe'] == 'catatan') _picu();
    } catch (_) {
      // Pesan tidak dikenal diabaikan.
    }
  }

  void _picu() {
    if (debounce == Duration.zero) {
      onPerubahan?.call();
      return;
    }
    _timerDebounce?.cancel();
    _timerDebounce = Timer(debounce, () => onPerubahan?.call());
  }

  void _ubah(StatusRealtime baru) {
    if (_dibuang || _status == baru) return;
    _status = baru;
    notifyListeners();
  }

  @override
  void dispose() {
    _dibuang = true;
    _aktif = false;
    _generasi++;
    _timerUlang?.cancel();
    _timerDebounce?.cancel();
    unawaited(_langganan?.cancel());
    unawaited(_koneksi?.tutup().catchError((_) {}));
    super.dispose();
  }
}
