import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/catatan.dart';
import 'local_store.dart';

/// Penyimpanan lokal berbasis SQLite (sqflite), menggantikan DatabaseHelper
/// pada workbook. Data bertahan setelah aplikasi ditutup, termasuk antrian.
class SqliteLocalStore implements LocalStore {
  SqliteLocalStore({this.namaFile = 'studylog_local.db'});

  final String namaFile;
  Future<Database>? _dbFuture;

  Future<Database> get _db => _dbFuture ??= _buka();

  Future<Database> _buka() async {
    final lokasi = join(await getDatabasesPath(), namaFile);
    return openDatabase(
      lokasi,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE catatan (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            client_id TEXT NOT NULL UNIQUE,
            server_id INTEGER,
            mata_kuliah_id INTEGER NOT NULL,
            mata_kuliah_kode TEXT NOT NULL DEFAULT '',
            mata_kuliah_nama TEXT NOT NULL DEFAULT '',
            topik TEXT NOT NULL,
            judul TEXT NOT NULL,
            isi TEXT NOT NULL,
            tanggal TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE antrian (
            client_id TEXT PRIMARY KEY,
            op TEXT NOT NULL,
            versi INTEGER NOT NULL DEFAULT 1,
            percobaan INTEGER NOT NULL DEFAULT 0,
            error TEXT,
            dibuat INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE cache (
            kunci TEXT PRIMARY KEY,
            nilai TEXT NOT NULL
          )
        ''');
      },
    );
  }

  static const _selectCatatan = '''
    SELECT c.*, CASE WHEN a.client_id IS NULL THEN 0 ELSE 1 END AS menunggu
      FROM catatan c
      LEFT JOIN antrian a ON a.client_id = c.client_id
  ''';

  Catatan _dariRow(Map<String, Object?> r) => Catatan(
        id: r['id'] as int,
        clientId: r['client_id'] as String,
        serverId: r['server_id'] as int?,
        menunggu: (r['menunggu'] as int? ?? 0) == 1,
        mataKuliahId: r['mata_kuliah_id'] as int,
        mataKuliahKode: r['mata_kuliah_kode'] as String,
        mataKuliahNama: r['mata_kuliah_nama'] as String,
        topik: r['topik'] as String,
        judul: r['judul'] as String,
        isi: r['isi'] as String,
        tanggal: DateTime.parse(r['tanggal'] as String),
      );

  Map<String, Object?> _keRow(Catatan c) => {
        'client_id': c.clientId,
        'server_id': c.serverId,
        'mata_kuliah_id': c.mataKuliahId,
        'mata_kuliah_kode': c.mataKuliahKode,
        'mata_kuliah_nama': c.mataKuliahNama,
        'topik': c.topik,
        'judul': c.judul,
        'isi': c.isi,
        'tanggal': c.tanggal.toIso8601String(),
      };

  @override
  Future<List<Catatan>> semuaCatatan() async {
    final db = await _db;
    final rows =
        await db.rawQuery('$_selectCatatan ORDER BY c.tanggal DESC, c.id DESC');
    return rows.map(_dariRow).toList();
  }

  @override
  Future<Catatan?> catatanById(int id) async {
    final db = await _db;
    final rows = await db.rawQuery('$_selectCatatan WHERE c.id = ?', [id]);
    return rows.isEmpty ? null : _dariRow(rows.first);
  }

  @override
  Future<Catatan?> catatanByClientId(String clientId) async {
    final db = await _db;
    final rows =
        await db.rawQuery('$_selectCatatan WHERE c.client_id = ?', [clientId]);
    return rows.isEmpty ? null : _dariRow(rows.first);
  }

  @override
  Future<Catatan> simpanCatatan(Catatan catatan) async {
    final db = await _db;
    return db.transaction((txn) async {
      final ada = await txn.query('catatan',
          columns: ['id'],
          where: 'client_id = ?',
          whereArgs: [catatan.clientId],
          limit: 1);
      if (ada.isNotEmpty) {
        final id = ada.first['id'] as int;
        await txn.update('catatan', _keRow(catatan),
            where: 'id = ?', whereArgs: [id]);
        return catatan.copyWith(id: id);
      }
      final id = await txn.insert('catatan', _keRow(catatan));
      return catatan.copyWith(id: id);
    });
  }

  @override
  Future<void> hapusCatatan(String clientId) async {
    final db = await _db;
    await db.delete('catatan', where: 'client_id = ?', whereArgs: [clientId]);
  }

  @override
  Future<void> setServerId(String clientId, int serverId) async {
    final db = await _db;
    await db.update('catatan', {'server_id': serverId},
        where: 'client_id = ?', whereArgs: [clientId]);
  }

  @override
  Future<List<ItemAntrian>> antrian() async {
    final db = await _db;
    final rows = await db.query('antrian', orderBy: 'dibuat ASC, client_id ASC');
    return rows
        .map((r) => ItemAntrian(
              clientId: r['client_id'] as String,
              op: OpAntrian.values.byName(r['op'] as String),
              versi: r['versi'] as int,
              percobaan: r['percobaan'] as int,
              error: r['error'] as String?,
            ))
        .toList();
  }

  @override
  Future<void> setAntrian(String clientId, OpAntrian op) async {
    final db = await _db;
    await db.transaction((txn) async {
      final ada = await txn.query('antrian',
          columns: ['versi'], where: 'client_id = ?', whereArgs: [clientId]);
      final sekarang = DateTime.now().microsecondsSinceEpoch;
      if (ada.isEmpty) {
        await txn.insert('antrian', {
          'client_id': clientId,
          'op': op.name,
          'versi': 1,
          'percobaan': 0,
          'error': null,
          'dibuat': sekarang,
        });
      } else {
        await txn.update(
          'antrian',
          {
            'op': op.name,
            'versi': (ada.first['versi'] as int) + 1,
            'percobaan': 0,
            'error': null,
          },
          where: 'client_id = ?',
          whereArgs: [clientId],
        );
      }
    });
  }

  @override
  Future<void> hapusAntrian(String clientId, int versi) async {
    final db = await _db;
    await db.delete('antrian',
        where: 'client_id = ? AND versi = ?', whereArgs: [clientId, versi]);
  }

  @override
  Future<void> catatGagal(String clientId, int versi, String error) async {
    final db = await _db;
    await db.rawUpdate(
      'UPDATE antrian SET percobaan = percobaan + 1, error = ? '
      'WHERE client_id = ? AND versi = ?',
      [error, clientId, versi],
    );
  }

  @override
  Future<String?> bacaCache(String kunci) async {
    final db = await _db;
    final rows = await db.query('cache',
        columns: ['nilai'], where: 'kunci = ?', whereArgs: [kunci]);
    return rows.isEmpty ? null : rows.first['nilai'] as String;
  }

  @override
  Future<void> tulisCache(String kunci, String nilai) async {
    final db = await _db;
    await db.insert('cache', {'kunci': kunci, 'nilai': nilai},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
