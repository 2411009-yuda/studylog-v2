import '../models/course.dart';
import '../models/jadwal.dart';
import 'api_client.dart';

/// Akses data mata kuliah dan jadwal (read-only).
class MataKuliahRepository {
  MataKuliahRepository(this.api);

  final ApiClient api;

  Future<List<Course>> semuaMataKuliah() async {
    final data = await api.get('/api/mata-kuliah') as List<dynamic>;
    return data.map((e) => Course.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Jadwal>> semuaJadwal() async {
    final data = await api.get('/api/jadwal') as List<dynamic>;
    return data.map((e) => Jadwal.fromJson(e as Map<String, dynamic>)).toList();
  }
}
