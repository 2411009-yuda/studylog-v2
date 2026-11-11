import '../models/catatan.dart';

/// Ringkasan satu mata kuliah yang muncul pada sekumpulan catatan.
class RingkasMataKuliah {
  const RingkasMataKuliah({
    required this.id,
    required this.kode,
    required this.nama,
    required this.jumlah,
  });

  final int id;
  final String kode;
  final String nama;

  /// Banyaknya catatan untuk mata kuliah ini pada daftar yang diringkas.
  final int jumlah;

  /// Nama untuk ditampilkan; cadangan jika nama belum terisi.
  String get label => nama.isEmpty ? 'Mata kuliah #$id' : nama;
}

/// Satu kelompok: sebuah mata kuliah beserta catatannya.
class KelompokCatatan {
  const KelompokCatatan(this.mataKuliah, this.catatan);

  final RingkasMataKuliah mataKuliah;
  final List<Catatan> catatan;
}

/// Daftar mata kuliah yang punya catatan di [daftar], urut nama A-Z.
/// Dibaca dari catatan itu sendiri, jadi tidak bergantung pada data mata
/// kuliah dari server dan tetap tersedia saat offline.
List<RingkasMataKuliah> ringkasMataKuliah(List<Catatan> daftar) {
  final jumlah = <int, int>{};
  final contoh = <int, Catatan>{};
  for (final c in daftar) {
    jumlah[c.mataKuliahId] = (jumlah[c.mataKuliahId] ?? 0) + 1;
    contoh.putIfAbsent(c.mataKuliahId, () => c);
  }
  final hasil = [
    for (final e in jumlah.entries)
      RingkasMataKuliah(
        id: e.key,
        kode: contoh[e.key]!.mataKuliahKode,
        nama: contoh[e.key]!.mataKuliahNama,
        jumlah: e.value,
      ),
  ];
  hasil.sort((a, b) {
    final t = a.label.toLowerCase().compareTo(b.label.toLowerCase());
    return t != 0 ? t : a.id.compareTo(b.id);
  });
  return hasil;
}

/// Hanya catatan milik mata kuliah [mataKuliahId]; null = semua.
/// Urutan daftar tidak diubah.
List<Catatan> filterMataKuliah(List<Catatan> daftar, int? mataKuliahId) {
  if (mataKuliahId == null) return List<Catatan>.of(daftar);
  return daftar.where((c) => c.mataKuliahId == mataKuliahId).toList();
}

/// Mengelompokkan [daftar] per mata kuliah (kelompok urut nama A-Z). Urutan
/// catatan di dalam tiap kelompok mengikuti urutan [daftar].
List<KelompokCatatan> kelompokkanPerMataKuliah(List<Catatan> daftar) {
  return [
    for (final mk in ringkasMataKuliah(daftar))
      KelompokCatatan(
        mk,
        daftar.where((c) => c.mataKuliahId == mk.id).toList(),
      ),
  ];
}
