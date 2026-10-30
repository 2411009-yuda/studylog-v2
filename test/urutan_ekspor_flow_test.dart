import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';
import 'test_helpers.dart';

/// Posisi vertikal sebuah judul di layar (untuk memeriksa urutan tampil).
double y(WidgetTester tester, String teks) =>
    tester.getTopLeft(find.text(teks)).dy;

FakeServer serverTigaCatatan() => FakeServer()
  ..seedCatatan(judul: 'Bumi', tanggal: '2026-10-28 10:00:00')
  ..seedCatatan(judul: 'Awan', tanggal: '2026-10-29 10:00:00')
  ..seedCatatan(judul: 'Cahaya', tanggal: '2026-10-30 10:00:00');

Future<void> bukaDaftar(WidgetTester tester) async {
  await tester.tap(find.text('Lihat Catatan'));
  await tester.pumpAndSettle();
}

Future<void> pilihUrutan(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Urutkan'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  group('Urutkan catatan', () {
    testWidgets('default terbaru, lalu terlama, lalu judul A-Z',
        (tester) async {
      await bukaApp(tester, serverTigaCatatan());
      await bukaDaftar(tester);

      expect(find.text('Urutan: Terbaru'), findsOneWidget);
      expect(y(tester, 'Cahaya'), lessThan(y(tester, 'Awan')));
      expect(y(tester, 'Awan'), lessThan(y(tester, 'Bumi')));

      await pilihUrutan(tester, 'Terlama');
      expect(find.text('Urutan: Terlama'), findsOneWidget);
      expect(y(tester, 'Bumi'), lessThan(y(tester, 'Awan')));
      expect(y(tester, 'Awan'), lessThan(y(tester, 'Cahaya')));

      await pilihUrutan(tester, 'Judul A–Z');
      expect(find.text('Urutan: Judul A–Z'), findsOneWidget);
      expect(y(tester, 'Awan'), lessThan(y(tester, 'Bumi')));
      expect(y(tester, 'Bumi'), lessThan(y(tester, 'Cahaya')));
    });

    testWidgets('urutan bertahan setelah catatan baru ditambahkan',
        (tester) async {
      final server = serverTigaCatatan();
      await bukaApp(tester, server);
      await bukaDaftar(tester);
      await pilihUrutan(tester, 'Judul A–Z');

      // Tambah catatan berjudul 'Aaa' lewat form dari Daftar.
      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();
      await isiForm(tester, judul: 'Aaa');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text('Urutan: Judul A–Z'), findsOneWidget);
      expect(y(tester, 'Aaa'), lessThan(y(tester, 'Awan')));
    });
  });

  group('Ekspor teks', () {
    testWidgets('Salin semua: teks mengikuti urutan terpilih', (tester) async {
      final ekspor = FakeEksporService();
      await bukaApp(tester, serverTigaCatatan(), ekspor: ekspor);
      await bukaDaftar(tester);
      await pilihUrutan(tester, 'Judul A–Z');

      await tester.tap(find.byTooltip('Ekspor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salin semua'));
      await tester.pumpAndSettle();

      final teks = ekspor.disalin.single;
      expect(teks, contains('Jumlah   : 3 catatan'));
      expect(teks, contains('Urutan   : Judul A–Z'));
      expect(teks.indexOf('[1] AWAN'), greaterThanOrEqualTo(0));
      expect(teks.indexOf('[1] AWAN'), lessThan(teks.indexOf('[2] BUMI')));
      expect(teks.indexOf('[2] BUMI'), lessThan(teks.indexOf('[3] CAHAYA')));
      expect(find.text('Semua catatan (3) disalin ke clipboard.'),
          findsOneWidget);
    });

    testWidgets('Bagikan semua memanggil share sheet', (tester) async {
      final ekspor = FakeEksporService();
      await bukaApp(tester, serverTigaCatatan(), ekspor: ekspor);
      await bukaDaftar(tester);

      await tester.tap(find.byTooltip('Ekspor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bagikan semua'));
      await tester.pumpAndSettle();

      expect(ekspor.dibagikan, hasLength(1));
      expect(ekspor.dibagikan.single, contains('[1] CAHAYA'));
      expect(ekspor.disalin, isEmpty);
    });

    testWidgets('Detail: salin dan bagikan satu catatan', (tester) async {
      final ekspor = FakeEksporService();
      final server = FakeServer()..seedCatatan(judul: 'Catatan Satu');
      await bukaApp(tester, server, ekspor: ekspor);
      await bukaDaftar(tester);
      await tester.tap(find.text('Catatan Satu'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Salin teks'));
      await tester.pumpAndSettle();
      expect(ekspor.disalin.single, startsWith('CATATAN SATU'));
      expect(ekspor.disalin.single, contains('setState memicu build ulang.'));
      expect(find.text('Catatan disalin ke clipboard.'), findsOneWidget);

      await tester.tap(find.byTooltip('Bagikan'));
      await tester.pumpAndSettle();
      expect(ekspor.dibagikan.single, startsWith('CATATAN SATU'));
    });

    testWidgets('kegagalan clipboard menampilkan pesan, bukan crash',
        (tester) async {
      final server = FakeServer()..seedCatatan(judul: 'Catatan Satu');
      await bukaApp(tester, server, ekspor: _EksporGagal());
      await bukaDaftar(tester);
      await tester.tap(find.text('Catatan Satu'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Salin teks'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gagal menyalin'), findsOneWidget);
    });
  });
}

class _EksporGagal extends FakeEksporService {
  @override
  Future<void> salin(String teks) async => throw StateError('clipboard');
}
