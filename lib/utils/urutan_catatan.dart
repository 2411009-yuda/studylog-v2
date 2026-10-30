import '../models/catatan.dart';

/// Pilihan urutan daftar catatan.
enum UrutanCatatan {
  terbaru('Terbaru'),
  terlama('Terlama'),
  judulAZ('Judul A–Z');

  const UrutanCatatan(this.label);

  final String label;
}

/// Mengembalikan salinan daftar yang sudah diurutkan. Urutan seri (tanggal
/// atau judul sama) diselesaikan dengan id agar hasilnya selalu stabil.
List<Catatan> urutkanCatatan(List<Catatan> daftar, UrutanCatatan urutan) {
  int byId(Catatan a, Catatan b) => (a.id ?? 0).compareTo(b.id ?? 0);

  final hasil = List<Catatan>.of(daftar);
  switch (urutan) {
    case UrutanCatatan.terbaru:
      hasil.sort((a, b) {
        final t = b.tanggal.compareTo(a.tanggal);
        return t != 0 ? t : byId(b, a);
      });
    case UrutanCatatan.terlama:
      hasil.sort((a, b) {
        final t = a.tanggal.compareTo(b.tanggal);
        return t != 0 ? t : byId(a, b);
      });
    case UrutanCatatan.judulAZ:
      hasil.sort((a, b) {
        final t = a.judul.toLowerCase().compareTo(b.judul.toLowerCase());
        return t != 0 ? t : byId(a, b);
      });
  }
  return hasil;
}
