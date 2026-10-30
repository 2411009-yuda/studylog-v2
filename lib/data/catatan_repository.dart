import '../models/catatan.dart';
import 'api_client.dart';

/// Akses data catatan. Hanya tahu cara bicara ke API; tidak tahu UI.
class CatatanRepository {
  CatatanRepository(this.api);

  final ApiClient api;

  Future<List<Catatan>> semua() async {
    final data = await api.get('/api/catatan') as List<dynamic>;
    return data
        .map((e) => Catatan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Catatan> tambah(Catatan catatan) async {
    final data = await api.post('/api/catatan', catatan.toRequestBody());
    return Catatan.fromJson(data as Map<String, dynamic>);
  }

  Future<Catatan> ubah(Catatan catatan) async {
    if (catatan.id == null) {
      throw ArgumentError('ID catatan tidak boleh kosong');
    }
    final data =
        await api.put('/api/catatan/${catatan.id}', catatan.toRequestBody());
    return Catatan.fromJson(data as Map<String, dynamic>);
  }

  Future<void> hapus(int id) async {
    await api.delete('/api/catatan/$id');
  }
}
