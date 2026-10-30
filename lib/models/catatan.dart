/// Satu catatan kuliah. Immutable.
///
/// Aplikasi bekerja offline-first, sehingga satu catatan punya tiga identitas:
/// - [id]       : id lokal (SQLite di perangkat), dipakai layar & route.
/// - [clientId] : UUID yang dibuat aplikasi; identitas lintas perangkat/server.
/// - [serverId] : id di MySQL; null sampai catatan berhasil dikirim.
class Catatan {
  const Catatan({
    this.id,
    this.clientId = '',
    this.serverId,
    this.menunggu = false,
    required this.mataKuliahId,
    this.mataKuliahKode = '',
    this.mataKuliahNama = '',
    required this.topik,
    required this.judul,
    required this.isi,
    required this.tanggal,
  });

  final int? id;
  final String clientId;
  final int? serverId;

  /// True jika ada perubahan catatan ini yang belum terkirim ke server.
  final bool menunggu;

  final int mataKuliahId;
  final String mataKuliahKode;
  final String mataKuliahNama;
  final String topik;
  final String judul;
  final String isi;
  final DateTime tanggal;

  Catatan copyWith({
    int? id,
    String? clientId,
    int? serverId,
    bool? menunggu,
    int? mataKuliahId,
    String? mataKuliahKode,
    String? mataKuliahNama,
    String? topik,
    String? judul,
    String? isi,
    DateTime? tanggal,
  }) =>
      Catatan(
        id: id ?? this.id,
        clientId: clientId ?? this.clientId,
        serverId: serverId ?? this.serverId,
        menunggu: menunggu ?? this.menunggu,
        mataKuliahId: mataKuliahId ?? this.mataKuliahId,
        mataKuliahKode: mataKuliahKode ?? this.mataKuliahKode,
        mataKuliahNama: mataKuliahNama ?? this.mataKuliahNama,
        topik: topik ?? this.topik,
        judul: judul ?? this.judul,
        isi: isi ?? this.isi,
        tanggal: tanggal ?? this.tanggal,
      );

  /// Bentuk JSON seperti yang dikirim server ('id' = id di server).
  Map<String, Object?> toJson() => {
        if (serverId != null) 'id': serverId,
        'clientId': clientId,
        'mataKuliahId': mataKuliahId,
        'mataKuliahKode': mataKuliahKode,
        'mataKuliahNama': mataKuliahNama,
        'topik': topik,
        'judul': judul,
        'isi': isi,
        'tanggal': tanggal.toIso8601String(),
      };

  /// Body untuk PUT /api/catatan/klien/:clientId. Tanggal pembuatan ikut
  /// dikirim agar catatan yang dibuat offline tetap bertanggal saat dibuat.
  Map<String, Object?> toRequestBody() => {
        'mataKuliahId': mataKuliahId,
        'topik': topik,
        'judul': judul,
        'isi': isi,
        'tanggal': tanggalServer,
      };

  factory Catatan.fromJson(Map<String, dynamic> json) => Catatan(
        serverId: json['id'] as int?,
        clientId: (json['clientId'] as String?) ?? '',
        mataKuliahId: json['mataKuliahId'] as int,
        mataKuliahKode: (json['mataKuliahKode'] as String?) ?? '',
        mataKuliahNama: (json['mataKuliahNama'] as String?) ?? '',
        topik: json['topik'] as String,
        judul: json['judul'] as String,
        isi: json['isi'] as String,
        // Menerima 'YYYY-MM-DD HH:MM:SS' (server) maupun format ISO 8601.
        tanggal: DateTime.parse(json['tanggal'] as String),
      );

  static String _dua(int n) => n.toString().padLeft(2, '0');

  /// 'YYYY-MM-DD HH:MM:SS' (waktu dinding), format yang dipakai server.
  String get tanggalServer => '${tanggal.year.toString().padLeft(4, '0')}-'
      '${_dua(tanggal.month)}-${_dua(tanggal.day)} '
      '${_dua(tanggal.hour)}:${_dua(tanggal.minute)}:${_dua(tanggal.second)}';

  /// Contoh: 30/10/2026
  String get tanggalLabel => '${tanggal.day}/${tanggal.month}/${tanggal.year}';

  /// Contoh: 30/10/2026 19:05
  String get tanggalWaktuLabel =>
      '$tanggalLabel ${_dua(tanggal.hour)}:${_dua(tanggal.minute)}';
}
