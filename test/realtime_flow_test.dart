import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_realtime.dart';
import 'fake_server.dart';
import 'test_helpers.dart';

Future<void> bukaDaftar(WidgetTester tester) async {
  await tester.tap(find.text('Lihat Catatan'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('indikator menunjukkan real-time aktif saat tersambung',
      (tester) async {
    final fake = FakeRealtime();
    await bukaApp(tester, FakeServer(), realtime: fake);

    expect(find.byTooltip('Real-time aktif'), findsOneWidget);
    expect(fake.jumlahTerbuka, 1);
  });

  testWidgets('tanpa real-time, indikator menunjukkan terputus', (tester) async {
    await bukaApp(tester, FakeServer());
    expect(find.byTooltip('Real-time terputus'), findsOneWidget);
  });

  testWidgets('catatan dari perangkat lain muncul TANPA menekan sinkron',
      (tester) async {
    final server = FakeServer();
    final fake = FakeRealtime();
    await bukaApp(tester, server, realtime: fake);
    await bukaDaftar(tester);
    expect(find.textContaining('Belum ada catatan'), findsOneWidget);

    server.dariPerangkatLain(judul: 'Langsung muncul');
    await tester.pumpAndSettle();

    expect(find.text('Langsung muncul'), findsOneWidget);
    expect(find.text('Total: 1 catatan'), findsOneWidget);
  });

  testWidgets('ubah dan hapus dari perangkat lain tampil seketika',
      (tester) async {
    final server = FakeServer();
    final satu = server.seedCatatan(judul: 'Satu');
    final dua = server.seedCatatan(judul: 'Dua');
    final fake = FakeRealtime();
    await bukaApp(tester, server, realtime: fake);
    await bukaDaftar(tester);
    expect(find.text('Satu'), findsOneWidget);
    expect(find.text('Dua'), findsOneWidget);

    server.ubahDariPerangkatLain(satu['clientId']! as String, judul: 'Satu (revisi)');
    await tester.pumpAndSettle();
    expect(find.text('Satu (revisi)'), findsOneWidget);
    expect(find.text('Satu'), findsNothing);

    server.hapusDariPerangkatLain(dua['clientId']! as String);
    await tester.pumpAndSettle();
    expect(find.text('Dua'), findsNothing);
    expect(find.text('Total: 1 catatan'), findsOneWidget);
  });

  testWidgets('perubahan di perangkat lain tampil juga di Detail yang terbuka',
      (tester) async {
    final server = FakeServer();
    final satu = server.seedCatatan(judul: 'Judul lama');
    final fake = FakeRealtime();
    await bukaApp(tester, server, realtime: fake);
    await bukaDaftar(tester);
    await tester.tap(find.text('Judul lama'));
    await tester.pumpAndSettle();

    server.ubahDariPerangkatLain(satu['clientId']! as String, judul: 'Judul baru');
    await tester.pumpAndSettle();

    expect(find.text('Detail Catatan'), findsOneWidget);
    expect(find.text('Judul baru'), findsOneWidget);
  });

  testWidgets('catatan buatan sendiri tidak menjadi ganda oleh kabar balasan',
      (tester) async {
    final server = FakeServer();
    final fake = FakeRealtime();
    await bukaApp(tester, server, realtime: fake);

    await tapPlus(tester);
    await isiForm(tester);
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await bukaDaftar(tester);

    expect(find.text('Dasar setState'), findsOneWidget);
    expect(find.text('Total: 1 catatan'), findsOneWidget);
    expect(server.catatan, hasLength(1));
    expect(server.putKlienCount, 1);
  });

  testWidgets('kabar selain catatan tidak memicu penarikan data',
      (tester) async {
    final server = FakeServer();
    final fake = FakeRealtime();
    await bukaApp(tester, server, realtime: fake);
    final awal = server.getCatatanCount;

    fake.kirim({'tipe': 'halo'});
    fake.kirimMentah('bukan json');
    await tester.pumpAndSettle();
    expect(server.getCatatanCount, awal);

    fake.kirim({'tipe': 'catatan', 'aksi': 'dibuat'});
    await tester.pumpAndSettle();
    expect(server.getCatatanCount, awal + 1);
  });

  testWidgets('sambungan putus lalu pulih: data yang terlewat dikejar',
      (tester) async {
    final server = FakeServer();
    final fake = FakeRealtime();
    await bukaApp(tester, server, realtime: fake);
    await bukaDaftar(tester);

    fake.putus();
    await tester.pump();
    expect(find.byTooltip('Real-time terputus'), findsOneWidget);

    // Terjadi saat terputus: tidak ada kabar yang sampai.
    server.seedCatatan(judul: 'Terlewat');
    await tester.pump(const Duration(milliseconds: 50)); // sambung ulang
    await tester.pumpAndSettle();

    expect(fake.sambungan, hasLength(2));
    expect(find.byTooltip('Real-time aktif'), findsOneWidget);
    expect(find.text('Terlewat'), findsOneWidget);
  });

  testWidgets('real-time tidak tersedia: polling cadangan tetap menarik data',
      (tester) async {
    final server = FakeServer()..seedCatatan(judul: 'Lewat polling');
    final fake = FakeRealtime()..gagalSambung = true;
    await bukaApp(tester, server,
        realtime: fake, interval: const Duration(seconds: 5));
    await bukaDaftar(tester);
    expect(find.byTooltip('Real-time terputus'), findsOneWidget);

    server.seedCatatan(judul: 'Catatan susulan');
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(find.text('Catatan susulan'), findsOneWidget);
  });

  testWidgets('background memutus WebSocket, kembali ke aplikasi menyambung lagi',
      (tester) async {
    final server = FakeServer();
    final fake = FakeRealtime();
    await bukaApp(tester, server, realtime: fake);
    expect(fake.jumlahTerbuka, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(fake.jumlahTerbuka, 0);
    expect(find.byTooltip('Real-time terputus'), findsOneWidget);

    // Saat di background ada perubahan di perangkat lain.
    server.seedCatatan(judul: 'Saat di background');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(fake.jumlahTerbuka, 1);
    expect(find.byTooltip('Real-time aktif'), findsOneWidget);
    await bukaDaftar(tester);
    expect(find.text('Saat di background'), findsOneWidget);
  });

  testWidgets('offline lalu kabar real-time: antrian dikirim begitu tersambung',
      (tester) async {
    final server = FakeServer();
    final fake = FakeRealtime();
    await bukaApp(tester, server, realtime: fake);

    server.down = true;
    await tapPlus(tester);
    await isiForm(tester);
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(server.catatan, isEmpty);

    // Server hidup lagi dan WebSocket tersambung ulang: antrian terkirim.
    server.down = false;
    fake.putus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(server.catatan, hasLength(1));
    expect(find.textContaining('Offline'), findsNothing);
  });
}
