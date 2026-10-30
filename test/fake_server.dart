import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:profil_mahasiswa/data/api_client.dart';

Map<String, Object?> _mk(int id, String kode, String nama, int sks,
        String dosen, String deskripsi, List<String> prasyarat) =>
    {
      'id': id,
      'kode': kode,
      'nama': nama,
      'sks': sks,
      'dosen': dosen,
      'deskripsi': deskripsi,
      'prasyarat': prasyarat,
    };

Map<String, Object?> _jd(
        int id, int mkId, int hari, String mulai, String selesai, String ruang) =>
    {
      'id': id,
      'mataKuliahId': mkId,
      'hari': hari,
      'jamMulai': mulai,
      'jamSelesai': selesai,
      'kelas': 'IFB5J',
      'ruang': ruang,
    };

/// Tiruan API StudyLog (data awal sama dengan db/schema.sql) untuk pengujian
/// tanpa jaringan. Perilaku endpoint meniru server Node.js.
class FakeServer {
  FakeServer() {
    mataKuliah.sort((a, b) => (a['nama'] as String).compareTo(b['nama'] as String));
  }

  final List<Map<String, Object?>> mataKuliah = [
    _mk(1, '000800', 'Penulisan dan Publikasi Ilmiah', 2,
        'YUSTIAN SERVANDA, S.Kom., M.Kom.', 'Menyusun karya tulis ilmiah.',
        ['Metodologi Penelitian']),
    _mk(2, '110700', 'Kriptografi', 3, "MUHAMMAD SAFI'I, S.Kom., M.Kom.",
        'Dasar penyandian data.', []),
    _mk(3, '111100', 'Penalaran Komputer', 3, 'ISA ROSITA, S.Kom., M.Cs.',
        'Representasi pengetahuan.', ['Kecerdasan Buatan']),
    _mk(4, '110600', 'Jaringan Nirkabel', 3, 'MARADONA, S.Kom., M.Kom.',
        'Jaringan tanpa kabel.', ['Jaringan Komputer']),
    _mk(5, '111000', 'Pemrograman Aplikasi Bergerak', 3,
        'PRAMUDYA PRIMA INSAN, S.Kom., M.Kom.', 'Membangun aplikasi mobile.',
        ['Algoritme dan Pemrograman']),
    _mk(6, '111600', 'Teknologi Aplikasi Bergerak', 3, 'ISTIA BUDI, S.T., M.M.',
        'Teknologi aplikasi bergerak.', ['Komunikasi Data']),
    _mk(7, '111500', 'Sistem Manajemen Basis Data', 3,
        'NASRUDDIN BIN IDRIS, S.Kom., M.Kom.', 'Pengelolaan basis data.',
        ['Sistem Basis Data']),
    _mk(8, '111400', 'Simulasi dan Game Komputer', 3,
        'HERUZULKIFLI ROWA, S.Kom, M.Kom', 'Dasar simulasi dan game.',
        ['Algoritma dan Pemrograman']),
  ];

  final List<Map<String, Object?>> jadwal = [
    _jd(1, 7, 1, '19:00', '20:30', 'LAB B (FIKOM)'),
    _jd(2, 6, 1, '20:30', '22:00', 'LAB A (FIKOM)'),
    _jd(3, 3, 2, '19:00', '20:30', 'A201'),
    _jd(4, 8, 2, '20:30', '22:00', 'LAB A (FIKOM)'),
    _jd(5, 2, 3, '20:30', '22:00', 'A301'),
    _jd(6, 1, 4, '19:00', '20:30', 'A203'),
    _jd(7, 4, 5, '19:00', '20:30', 'LAB JARINGAN (FIKOM)'),
    _jd(8, 5, 5, '20:30', '22:00', 'LAB A (FIKOM)'),
  ];

  /// Isi tabel catatan (urutan sisip; GET mengembalikan terbaru dulu).
  final List<Map<String, Object?>> catatan = [];
  int _berikutnya = 1;

  /// Jika true, semua permintaan gagal seperti server mati.
  bool down = false;

  /// Jika true, server MEMPROSES permintaan tetapi balasannya hilang di jalan
  /// (aplikasi melihat kegagalan jaringan). Menguji pengiriman ulang idempoten.
  bool dropResponse = false;

  /// Jika diisi, PUT klien ditolak dengan 400 dan pesan ini.
  String? tolakKlien;

  /// Dipanggil di tengah pemrosesan PUT klien (menyimulasikan pengguna yang
  /// mengubah data saat pengiriman sedang berjalan).
  Future<void> Function()? onPutKlien;

  int putKlienCount = 0;
  int deleteKlienCount = 0;
  int _urutClient = 1;

  /// Tanggal yang diberikan "server" pada catatan baru.
  String tanggalBaru = '2026-10-30 20:40:00';

  late final http.Client client = MockClient(_handle);
  ApiClient get api => ApiClient(client: client, baseUrl: 'http://fake');

  /// Menambah catatan langsung ke "database" tanpa lewat UI.
  Map<String, Object?> seedCatatan({
    int mataKuliahId = 5,
    String topik = 'State',
    String judul = 'Dasar setState',
    String isi = 'setState memicu build ulang.',
    String? tanggal,
    String? clientId,
  }) {
    final mk = mataKuliah.firstWhere((m) => m['id'] == mataKuliahId);
    final row = <String, Object?>{
      'id': _berikutnya++,
      'clientId': clientId ??
          '00000000-0000-4000-8000-${(_urutClient++).toString().padLeft(12, '0')}',
      'mataKuliahId': mataKuliahId,
      'mataKuliahKode': mk['kode'],
      'mataKuliahNama': mk['nama'],
      'topik': topik,
      'judul': judul,
      'isi': isi,
      'tanggal': tanggal ?? tanggalBaru,
    };
    catatan.add(row);
    return row;
  }

  http.Response _json(Object? body, [int code = 200]) => http.Response(
        jsonEncode(body),
        code,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );

  http.Response _error(int code, String pesan) => _json({'error': pesan}, code);

  Future<http.Response> _handle(http.Request r) async {
    if (down) throw http.ClientException('connection refused');
    final balasan = await _proses(r);
    if (dropResponse) throw http.ClientException('connection reset');
    return balasan;
  }

  Future<http.Response> _proses(http.Request r) async {

    final seg = r.url.pathSegments;
    if (seg.length < 2 || seg[0] != 'api') return _error(404, 'Endpoint tidak ditemukan');

    if (r.method == 'GET' && seg[1] == 'mata-kuliah') return _json(mataKuliah);
    if (r.method == 'GET' && seg[1] == 'jadwal') return _json(jadwal);
    if (seg[1] != 'catatan') return _error(404, 'Endpoint tidak ditemukan');

    if (seg.length == 2) {
      if (r.method == 'GET') return _json(catatan.reversed.toList());
      if (r.method == 'POST') {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final salah = _validasi(body);
        if (salah != null) return _error(400, salah);
        final row = seedCatatan(
          mataKuliahId: body['mataKuliahId'] as int,
          topik: (body['topik'] as String).trim(),
          judul: (body['judul'] as String).trim(),
          isi: (body['isi'] as String).trim(),
        );
        return _json(row, 201);
      }
    }

    // ---- Endpoint sinkronisasi (idempoten, dialamatkan dengan clientId) ----
    if (seg.length == 4 && seg[2] == 'klien') {
      final clientId = seg[3];
      if (r.method == 'DELETE') {
        deleteKlienCount++;
        catatan.removeWhere((c) => c['clientId'] == clientId);
        return http.Response('', 204);
      }
      if (r.method == 'PUT') {
        if (tolakKlien != null) return _error(400, tolakKlien!);
        putKlienCount++;
        await onPutKlien?.call();
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final salah = _validasi(body);
        if (salah != null) return _error(400, salah);
        final mk = mataKuliah.firstWhere((m) => m['id'] == body['mataKuliahId']);
        final index = catatan.indexWhere((c) => c['clientId'] == clientId);
        if (index >= 0) {
          // Tanggal pembuatan tidak diubah oleh pembaruan.
          catatan[index] = {
            ...catatan[index],
            'mataKuliahId': mk['id'],
            'mataKuliahKode': mk['kode'],
            'mataKuliahNama': mk['nama'],
            'topik': (body['topik'] as String).trim(),
            'judul': (body['judul'] as String).trim(),
            'isi': (body['isi'] as String).trim(),
          };
          return _json(catatan[index]);
        }
        final row = seedCatatan(
          mataKuliahId: body['mataKuliahId'] as int,
          topik: (body['topik'] as String).trim(),
          judul: (body['judul'] as String).trim(),
          isi: (body['isi'] as String).trim(),
          tanggal: body['tanggal'] as String?,
          clientId: clientId,
        );
        return _json(row, 201);
      }
    }

    if (seg.length == 3) {
      final id = int.tryParse(seg[2]);
      final index = catatan.indexWhere((c) => c['id'] == id);
      if (index < 0) return _error(404, 'Catatan tidak ditemukan');
      if (r.method == 'GET') return _json(catatan[index]);
      if (r.method == 'PUT') {
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        final salah = _validasi(body);
        if (salah != null) return _error(400, salah);
        final mk = mataKuliah.firstWhere((m) => m['id'] == body['mataKuliahId']);
        catatan[index] = {
          ...catatan[index],
          'mataKuliahId': mk['id'],
          'mataKuliahKode': mk['kode'],
          'mataKuliahNama': mk['nama'],
          'topik': (body['topik'] as String).trim(),
          'judul': (body['judul'] as String).trim(),
          'isi': (body['isi'] as String).trim(),
        };
        return _json(catatan[index]);
      }
      if (r.method == 'DELETE') {
        catatan.removeAt(index);
        return http.Response('', 204);
      }
    }
    return _error(404, 'Endpoint tidak ditemukan');
  }

  String? _validasi(Map<String, dynamic> b) {
    final mkId = b['mataKuliahId'];
    if (mkId is! int || !mataKuliah.any((m) => m['id'] == mkId)) {
      return 'Mata kuliah wajib dipilih';
    }
    if ((b['topik'] as String? ?? '').trim().length < 3) {
      return 'Topik minimal 3 karakter';
    }
    if ((b['judul'] as String? ?? '').trim().isEmpty) return 'Judul wajib diisi';
    if ((b['isi'] as String? ?? '').trim().isEmpty) return 'Isi catatan wajib diisi';
    return null;
  }
}
