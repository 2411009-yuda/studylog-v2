import 'dart:convert';

import '../models/penilaian_dosen.dart';
import 'api_client.dart';
import 'local_store.dart';
import 'sinkron_service.dart' show HasilSinkron;

/// Satu penilaian di salinan lokal. [tersinkron] = server sudah pernah
/// menerima/mengirim penilaian ini (dipakai mendeteksi penghapusan di
/// perangkat lain).
class _Baris {
  _Baris(this.data, this.tersinkron);

  PenilaianDosen data;
  bool tersinkron;
}

/// Satu perubahan dalam antrian (outbox). Hanya ada SATU entri per
/// (mata kuliah, pertemuan): perubahan baru menggantikan yang lama.
class _Antri {
  _Antri({
    required this.mataKuliahId,
    required this.pertemuan,
    required this.op,
    required this.urut,
    this.versi = 1,
    this.percobaan = 0,
    this.error,
  });

  final int mataKuliahId;
  final int pertemuan;
  OpAntrian op;

  /// Naik setiap kali entri diganti, agar pengiriman yang selesai tidak
  /// menghapus perubahan lebih baru yang dibuat saat pengiriman berjalan.
  int versi;
  int percobaan;
  String? error;
  final int urut;

  Map<String, Object?> toJson() => {
        'mataKuliahId': mataKuliahId,
        'pertemuan': pertemuan,
        'op': op.name,
        'versi': versi,
        'percobaan': percobaan,
        'error': error,
        'urut': urut,
      };

  factory _Antri.fromJson(Map<String, dynamic> j) => _Antri(
        mataKuliahId: j['mataKuliahId'] as int,
        pertemuan: j['pertemuan'] as int,
        op: OpAntrian.values.byName(j['op'] as String),
        versi: j['versi'] as int,
        percobaan: j['percobaan'] as int,
        error: j['error'] as String?,
        urut: j['urut'] as int,
      );
}

/// Penilaian dosen, OFFLINE-FIRST seperti catatan: membaca dan menulis selalu
/// ke penyimpanan lokal, lalu setiap perubahan dicatat ke antrian untuk dikirim
/// ke server lewat [sinkronkan]. Tidak pernah menunggu jaringan.
///
/// Salinan lokal dan antrian disimpan sebagai JSON di cache [LocalStore],
/// dan dijaga di memori: semua perubahan dilakukan sinkron (tanpa await di
/// tengahnya), sehingga aman dari tabrakan antara pengguna dan sinkronisasi.
class PenilaianRepository {
  PenilaianRepository(this.api, this.local, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final ApiClient api;
  final LocalStore local;
  final DateTime Function() _clock;

  static const _kunciData = 'penilaian_dosen';
  static const _kunciAntrian = 'penilaian_antrian';

  final Map<String, _Baris> _baris = {};
  final Map<String, _Antri> _antrian = {};
  int _urut = 0;
  Future<void>? _siap;

  static String _kunci(int mataKuliahId, int pertemuan) =>
      '$mataKuliahId:$pertemuan';

  static String _path(int mataKuliahId, int pertemuan) =>
      '/api/penilaian/$mataKuliahId/$pertemuan';

  /// Kesalahan 4xx berarti server menolak isi permintaan: mengulang tidak
  /// akan menolong. (408/429 tetap dianggap sementara.)
  static bool _permanen(ApiException e) {
    final kode = e.statusCode;
    return kode != null && kode >= 400 && kode < 500 && kode != 408 && kode != 429;
  }

  // ---- Memuat / menyimpan salinan lokal ----

  Future<void> _pastikanMuat() => _siap ??= _muatDariLokal();

  Future<void> _muatDariLokal() async {
    try {
      final json = await local.bacaCache(_kunciData);
      if (json != null) {
        for (final e in jsonDecode(json) as List<dynamic>) {
          final m = e as Map<String, dynamic>;
          final p = PenilaianDosen.fromJson(m);
          // Cache versi lama tidak punya penanda: datanya berasal dari server.
          _baris[_kunci(p.mataKuliahId, p.pertemuan)] =
              _Baris(p, (m['tersinkron'] as bool?) ?? true);
        }
      }
    } catch (_) {
      _baris.clear(); // cache rusak: mulai dari kosong
    }
    try {
      final json = await local.bacaCache(_kunciAntrian);
      if (json != null) {
        for (final e in jsonDecode(json) as List<dynamic>) {
          final a = _Antri.fromJson(e as Map<String, dynamic>);
          _antrian[_kunci(a.mataKuliahId, a.pertemuan)] = a;
          if (a.urut > _urut) _urut = a.urut;
        }
      }
    } catch (_) {
      _antrian.clear();
    }
  }

  Future<void> _simpanKeLokal() async {
    await local.tulisCache(
      _kunciData,
      jsonEncode([
        for (final b in _baris.values)
          {...b.data.toJson(), 'tersinkron': b.tersinkron},
      ]),
    );
    await local.tulisCache(
      _kunciAntrian,
      jsonEncode([for (final a in _antrian.values) a.toJson()]),
    );
  }

  // ---- Membaca ----

  /// Semua penilaian lokal; [PenilaianDosen.menunggu] dan
  /// [PenilaianDosen.galat] diisi dari antrian.
  Future<List<PenilaianDosen>> semua() async {
    await _pastikanMuat();
    return [
      for (final e in _baris.entries)
        e.value.data.denganStatus(
          menunggu: _antrian.containsKey(e.key),
          galat: _antrian[e.key]?.error,
        ),
    ];
  }

  /// Jumlah perubahan di antrian (termasuk yang ditolak). Panggil setelah
  /// [semua] atau [sinkronkan] agar data sudah dimuat.
  int get tertunda => _antrian.length;

  /// Dari [tertunda], berapa yang ditolak permanen oleh server.
  int get ditolak => _antrian.values.where((a) => a.error != null).length;

  // ---- Menulis (lokal dulu, server menyusul) ----

  void _setAntrian(int mataKuliahId, int pertemuan, OpAntrian op) {
    final k = _kunci(mataKuliahId, pertemuan);
    final ada = _antrian[k];
    if (ada == null) {
      _antrian[k] = _Antri(
        mataKuliahId: mataKuliahId,
        pertemuan: pertemuan,
        op: op,
        urut: ++_urut,
      );
    } else {
      ada
        ..op = op
        ..versi += 1
        ..percobaan = 0
        ..error = null;
    }
  }

  /// Membuat atau mengganti penilaian di perangkat, lalu masuk antrian.
  Future<void> simpan({
    required int mataKuliahId,
    required int pertemuan,
    required Map<String, int> skor,
    required String komentar,
  }) async {
    await _pastikanMuat();
    final k = _kunci(mataKuliahId, pertemuan);
    _baris[k] = _Baris(
      PenilaianDosen(
        mataKuliahId: mataKuliahId,
        pertemuan: pertemuan,
        skor: Map<String, int>.from(skor),
        komentar: komentar.trim(),
        dinilaiPada: _clock(),
      ),
      _baris[k]?.tersinkron ?? false,
    );
    _setAntrian(mataKuliahId, pertemuan, OpAntrian.upsert);
    await _simpanKeLokal();
  }

  /// Menghapus di perangkat sekarang juga; penghapusan di server menyusul.
  Future<void> hapus(int mataKuliahId, int pertemuan) async {
    await _pastikanMuat();
    final k = _kunci(mataKuliahId, pertemuan);
    if (_baris.remove(k) == null) return;
    _setAntrian(mataKuliahId, pertemuan, OpAntrian.hapus);
    await _simpanKeLokal();
  }

  // ---- Sinkronisasi ----

  /// 1. kirim antrian (berurutan, idempoten dengan alamat matkul+pertemuan);
  /// 2. tarik data server dan satukan ke lokal.
  Future<HasilSinkron> sinkronkan() async {
    await _pastikanMuat();
    var terkirim = 0;
    var ditolakBaru = 0;
    String? pesan;

    final antrian = _antrian.values.toList()
      ..sort((a, b) => a.urut.compareTo(b.urut));

    for (final item in antrian) {
      final k = _kunci(item.mataKuliahId, item.pertemuan);
      final op = item.op;
      final versi = item.versi;
      try {
        if (op == OpAntrian.hapus) {
          await api.delete(_path(item.mataKuliahId, item.pertemuan));
        } else {
          final baris = _baris[k];
          if (baris == null) {
            // Sudah tidak ada di lokal; tidak ada yang dikirim.
            if (_antrian[k]?.versi == versi) _antrian.remove(k);
            await _simpanKeLokal();
            continue;
          }
          await api.put(_path(item.mataKuliahId, item.pertemuan), {
            'skor': baris.data.skor,
            'komentar': baris.data.komentar,
          });
          // Hanya menandai "server sudah punya"; isi lokal tidak ditimpa
          // karena pengguna mungkin mengubahnya saat pengiriman berjalan.
          _baris[k]?.tersinkron = true;
        }
        if (_antrian[k]?.versi == versi) _antrian.remove(k);
        await _simpanKeLokal();
        terkirim++;
      } on ApiException catch (e) {
        if (_permanen(e)) {
          final a = _antrian[k];
          if (a != null && a.versi == versi) {
            a
              ..percobaan += 1
              ..error = e.message;
          }
          await _simpanKeLokal();
          ditolakBaru++;
          pesan = e.message;
          continue;
        }
        return HasilSinkron(
            offline: true,
            terkirim: terkirim,
            ditolak: ditolakBaru,
            pesan: e.message);
      }
    }

    try {
      final data = await api.get('/api/penilaian') as List<dynamic>;
      _satukan(data
          .map((e) => PenilaianDosen.fromJson(e as Map<String, dynamic>))
          .toList());
      await _simpanKeLokal();
    } on ApiException catch (e) {
      return HasilSinkron(
          offline: true,
          terkirim: terkirim,
          ditolak: ditolakBaru,
          pesan: e.message);
    }

    return HasilSinkron(terkirim: terkirim, ditolak: ditolakBaru, pesan: pesan);
  }

  /// Menyatukan snapshot server ke lokal (sinkron, tanpa await). Penilaian
  /// yang masih punya perubahan tertunda TIDAK ditimpa: perubahan lokal menang
  /// saat dikirim nanti.
  void _satukan(List<PenilaianDosen> dariServer) {
    final tertundaKunci = _antrian.keys.toSet();
    final kunciServer = <String>{};

    for (final s in dariServer) {
      final k = _kunci(s.mataKuliahId, s.pertemuan);
      kunciServer.add(k);
      if (tertundaKunci.contains(k)) continue;
      _baris[k] = _Baris(s, true);
    }

    // Ada di lokal, sudah pernah di server, tidak tertunda, tapi hilang di
    // server = dihapus dari perangkat lain.
    for (final k in _baris.keys.toList()) {
      if (!kunciServer.contains(k) &&
          _baris[k]!.tersinkron &&
          !tertundaKunci.contains(k)) {
        _baris.remove(k);
      }
    }
  }
}
