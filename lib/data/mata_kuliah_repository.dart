import 'dart:convert';

import '../models/course.dart';
import '../models/jadwal.dart';
import 'api_client.dart';
import 'local_store.dart';

/// Hasil pemuatan mata kuliah + jadwal.
class DataMataKuliah {
  const DataMataKuliah({
    required this.courses,
    required this.jadwal,
    required this.dariCache,
  });

  final List<Course> courses;
  final List<Jadwal> jadwal;

  /// True jika server tidak terjangkau dan data diambil dari cache perangkat.
  final bool dariCache;
}

/// Mata kuliah dan jadwal (read-only). Setiap pemuatan sukses disimpan ke
/// cache lokal, sehingga dropdown dan tombol + tetap berfungsi saat offline.
class MataKuliahRepository {
  MataKuliahRepository(this.api, this.local);

  final ApiClient api;
  final LocalStore local;

  static const _kunciMk = 'mata_kuliah';
  static const _kunciJadwal = 'jadwal';

  List<Course> _parseMk(String json) => (jsonDecode(json) as List<dynamic>)
      .map((e) => Course.fromJson(e as Map<String, dynamic>))
      .toList();

  List<Jadwal> _parseJadwal(String json) => (jsonDecode(json) as List<dynamic>)
      .map((e) => Jadwal.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<DataMataKuliah> muat() async {
    try {
      final mk = await api.get('/api/mata-kuliah') as List<dynamic>;
      final jd = await api.get('/api/jadwal') as List<dynamic>;
      final mkJson = jsonEncode(mk);
      final jdJson = jsonEncode(jd);
      await local.tulisCache(_kunciMk, mkJson);
      await local.tulisCache(_kunciJadwal, jdJson);
      return DataMataKuliah(
        courses: _parseMk(mkJson),
        jadwal: _parseJadwal(jdJson),
        dariCache: false,
      );
    } on ApiException {
      final mkJson = await local.bacaCache(_kunciMk);
      final jdJson = await local.bacaCache(_kunciJadwal);
      // Belum pernah berhasil dimuat: tidak ada yang bisa ditampilkan.
      if (mkJson == null || jdJson == null) rethrow;
      return DataMataKuliah(
        courses: _parseMk(mkJson),
        jadwal: _parseJadwal(jdJson),
        dariCache: true,
      );
    }
  }
}
