import '../models/catatan.dart';

String _dua(int n) => n.toString().padLeft(2, '0');

String _waktu(DateTime t) =>
    '${t.day}/${t.month}/${t.year} ${_dua(t.hour)}:${_dua(t.minute)}';

/// Teks siap salin/bagikan untuk satu catatan.
String eksporSatu(Catatan c) {
  final mk = c.mataKuliahKode.isEmpty
      ? c.mataKuliahNama
      : '${c.mataKuliahNama} (${c.mataKuliahKode})';
  return [
    c.judul.toUpperCase(),
    'Mata kuliah : $mk',
    'Topik       : ${c.topik}',
    'Dibuat      : ${c.tanggalWaktuLabel}',
    '',
    c.isi,
  ].join('\n');
}

/// Teks siap salin/bagikan untuk banyak catatan, mengikuti urutan [daftar].
String eksporSemua(
  List<Catatan> daftar, {
  required DateTime waktu,
  required String urutan,
}) {
  const garis = '------------------------------';
  final buffer = StringBuffer()
    ..writeln('StudyLog - Ekspor Catatan')
    ..writeln('Diekspor : ${_waktu(waktu)}')
    ..writeln('Jumlah   : ${daftar.length} catatan')
    ..writeln('Urutan   : $urutan');

  for (var i = 0; i < daftar.length; i++) {
    buffer
      ..writeln()
      ..writeln(garis)
      ..writeln('[${i + 1}] ${eksporSatu(daftar[i])}');
  }
  return buffer.toString().trimRight();
}
