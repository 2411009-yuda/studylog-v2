import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';
import 'in_memory_local_store.dart';
import 'test_helpers.dart';

const _bannerOffline = 'Offline · menampilkan data tersimpan di perangkat';
const _simpanOffline = 'Disimpan offline. Akan disinkronkan saat terhubung.';

/// Menyimulasikan pengguna yang sudah pernah memakai aplikasi saat online
/// (cache mata kuliah & jadwal terisi), lalu membuka aplikasi TANPA koneksi.
Future<InMemoryLocalStore> bukaTanpaKoneksi(
  WidgetTester tester,
  FakeServer server, {
  Duration? interval,
}) async {
  final local = InMemoryLocalStore();
  await bukaApp(tester, server, local: local); // online: cache terisi
  server.down = true;
  await tester.pumpWidget(const SizedBox()); // tutup aplikasi
  await bukaApp(tester, server, local: local, interval: interval);
  return local;
}

Future<void> buatCatatanLewatPlus(WidgetTester tester) async {
  await tapPlus(tester);
  await isiForm(tester);
  await tester.tap(find.text('Simpan'));
  await tester.pumpAndSettle();
}

Future<void> bukaDaftarCatatan(WidgetTester tester) async {
  await tester.tap(find.text('Lihat Catatan'));
  await tester.pumpAndSettle();
}

void main() {
  group('Offline-first', () {
    testWidgets('simpan saat offline masuk antrian, lalu terkirim saat online',
        (tester) async {
      final server = FakeServer();
      await bukaTanpaKoneksi(tester, server);
      expect(find.text(_bannerOffline), findsOneWidget);

      // Tombol + tetap mengisi mata kuliah dari jadwal yang tersimpan (cache).
      await tapPlus(tester);
      expect(
        tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>)).value,
        5,
      );
      await isiForm(tester);
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      expect(find.text(_simpanOffline), findsWidgets);
      expect(server.catatan, isEmpty);
      expect(find.text('Offline · 1 perubahan menunggu sinkron'), findsOneWidget);

      // Catatan sudah tampil di daftar dengan tanda menunggu sinkron.
      await bukaDaftarCatatan(tester);
      expect(find.text('Dasar setState'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);

      // Server kembali: sinkronisasi manual mengirim antrian.
      server.down = false;
      await tester.tap(find.byTooltip('Sinkronkan'));
      await tester.pumpAndSettle();

      expect(server.catatan.single['judul'], 'Dasar setState');
      expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
      expect(find.textContaining('Offline'), findsNothing);
    });

    testWidgets('detail catatan yang belum terkirim menampilkan penandanya',
        (tester) async {
      await bukaTanpaKoneksi(tester, FakeServer());
      await buatCatatanLewatPlus(tester);
      await bukaDaftarCatatan(tester);

      await tester.tap(find.text('Dasar setState'));
      await tester.pumpAndSettle();

      expect(find.text('Menunggu sinkron'), findsOneWidget);
    });

    testWidgets('ubah dan hapus saat offline tetap berfungsi dan tersinkron',
        (tester) async {
      final server = FakeServer()..seedCatatan(judul: 'Awal');
      final local = InMemoryLocalStore();
      await bukaApp(tester, server, local: local); // tarik catatan dari server
      server.down = true;
      await tester.pumpWidget(const SizedBox());
      await bukaApp(tester, server, local: local);
      await bukaDaftarCatatan(tester);

      // Ubah judul saat offline.
      await tester.tap(find.text('Awal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'Diubah offline');
      await tester.pump();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Diubah offline'), findsOneWidget);
      expect(server.catatan.single['judul'], 'Awal');

      // Hapus saat offline: hilang di perangkat seketika.
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus').last);
      await tester.pumpAndSettle();
      expect(find.text('Daftar Catatan'), findsOneWidget);
      expect(find.text('Diubah offline'), findsNothing);
      expect(server.catatan, hasLength(1)); // server belum tahu

      // Online lagi: penghapusan sampai ke server.
      server.down = false;
      await tester.tap(find.byTooltip('Sinkronkan'));
      await tester.pumpAndSettle();
      expect(server.catatan, isEmpty);
    });

    testWidgets('kembali dari background (resume) memicu sinkronisasi',
        (tester) async {
      final server = FakeServer();
      await bukaTanpaKoneksi(tester, server);
      await buatCatatanLewatPlus(tester);
      expect(server.catatan, isEmpty);

      server.down = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(server.catatan, hasLength(1));
      expect(find.textContaining('Offline'), findsNothing);
    });

    testWidgets('sinkronisasi berkala mengirim antrian saat server kembali',
        (tester) async {
      final server = FakeServer();
      await bukaTanpaKoneksi(tester, server,
          interval: const Duration(seconds: 5));
      await buatCatatanLewatPlus(tester);
      expect(server.catatan, isEmpty);

      server.down = false;
      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      expect(server.catatan, hasLength(1));
    });

    testWidgets('tab Mata Kuliah memakai cache saat offline', (tester) async {
      await bukaTanpaKoneksi(tester, FakeServer());

      await tapTab(tester, 'Mata Kuliah');

      expect(find.text('8 mata kuliah · 23 SKS'), findsOneWidget);
      expect(find.text(_bannerOffline), findsOneWidget);
    });

    testWidgets('pertama kali dibuka tanpa koneksi: pesan jelas, tidak crash',
        (tester) async {
      final server = FakeServer()..down = true;
      await bukaApp(tester, server);
      await tapTab(tester, 'Mata Kuliah');

      expect(find.textContaining('Tidak dapat memuat mata kuliah'),
          findsOneWidget);

      // Server hidup: tombol Coba lagi memulihkan.
      server.down = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('8 mata kuliah · 23 SKS'), findsOneWidget);
    });
  });

  group('Sinkronisasi dengan perangkat lain', () {
    testWidgets('catatan dari perangkat lain muncul setelah sinkron',
        (tester) async {
      final server = FakeServer();
      await bukaApp(tester, server);
      await bukaDaftarCatatan(tester);
      expect(find.textContaining('Belum ada catatan'), findsOneWidget);

      server.seedCatatan(judul: 'Dari HP lain');
      await tester.tap(find.byTooltip('Sinkronkan'));
      await tester.pumpAndSettle();

      expect(find.text('Dari HP lain'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
    });

    testWidgets('catatan yang dihapus di perangkat lain hilang setelah sinkron',
        (tester) async {
      final server = FakeServer()..seedCatatan(judul: 'Akan dihapus');
      await bukaApp(tester, server);
      await bukaDaftarCatatan(tester);
      expect(find.text('Akan dihapus'), findsOneWidget);

      server.catatan.clear();
      await tester.tap(find.byTooltip('Sinkronkan'));
      await tester.pumpAndSettle();

      expect(find.text('Akan dihapus'), findsNothing);
    });

    testWidgets('pasang ulang (SQLite kosong): data kembali dari server',
        (tester) async {
      final server = FakeServer()..seedCatatan(judul: 'Tersimpan di MySQL');
      await bukaApp(tester, server); // penyimpanan lokal baru dan kosong
      await bukaDaftarCatatan(tester);

      expect(find.text('Tersimpan di MySQL'), findsOneWidget);
    });
  });

  testWidgets('perubahan ditolak server ditampilkan dan data tidak hilang',
      (tester) async {
    final server = FakeServer()..tolakKlien = 'Mata kuliah tidak ditemukan';
    await bukaApp(tester, server);

    await buatCatatanLewatPlus(tester);

    expect(find.text('1 perubahan ditolak server: Mata kuliah tidak ditemukan'),
        findsOneWidget);
    await bukaDaftarCatatan(tester);
    expect(find.text('Dasar setState'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    expect(server.catatan, isEmpty);
  });
}
