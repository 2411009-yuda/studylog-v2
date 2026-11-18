import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/config/app_info.dart';

import 'fake_server.dart';
import 'test_helpers.dart';

Future<void> bukaTentang(WidgetTester tester) async {
  await bukaApp(tester, FakeServer());
  await tester.tap(find.text('Tentang Aplikasi'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Beranda -> Tentang Aplikasi menampilkan info aplikasi',
          (tester) async {
        await bukaTentang(tester);

        expect(find.text('Tentang Aplikasi'), findsOneWidget); // judul AppBar
        expect(find.text('StudyLog'), findsOneWidget);
        expect(find.text('Aplikasi Catatan Perkuliahan'), findsOneWidget);
        expect(find.text('Versi ${AppInfo.versi}'), findsOneWidget);
        expect(find.text(AppInfo.deskripsi), findsOneWidget);
        expect(find.text('Fitur'), findsOneWidget);
        expect(find.text('Teknologi'), findsOneWidget);
        expect(find.text('Flutter'), findsOneWidget);
      });

  testWidgets('semua fitur yang tercantum tampil', (tester) async {
    await bukaTentang(tester);

    for (final f in AppInfo.fitur) {
      expect(find.text(f.judul), findsOneWidget);
      expect(find.text(f.keterangan), findsOneWidget);
    }
  });

  testWidgets('tombol kembali dari Tentang menuju Beranda, bukan keluar',
          (tester) async {
        await bukaTentang(tester);

        await tester.pageBack();
        await tester.pumpAndSettle();

        expect(find.text('StudyLog'), findsOneWidget); // judul AppBar Beranda
        expect(find.text('Tentang Aplikasi'), findsOneWidget); // tile di Beranda
        expect(find.text('Catatan Perkuliahan'), findsOneWidget);
      });

  test('versi di AppInfo sama dengan versi di pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('version: ${AppInfo.versi}+'));
  });
}