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
    expect(find.text('Pengembang'), findsOneWidget);
  });

  testWidgets('bagian pengembang mengikuti data profil', (tester) async {
    await bukaTentang(tester);

    expect(find.text('Yuda Pratama Putra'), findsOneWidget);
    expect(find.text('2411009'), findsOneWidget);
    expect(find.text(AppInfo.institusi), findsOneWidget);
    expect(find.text(AppInfo.mataKuliah), findsOneWidget);
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

  testWidgets('nama yang diedit di Profil ikut berubah di Tentang',
      (tester) async {
    await bukaApp(tester, FakeServer());
    await tapTab(tester, 'Profil');
    await tester.tap(find.text('Edit Profil'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Nama Baru');
    await tester.pump();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    await tapTab(tester, 'Beranda');
    await tester.tap(find.text('Tentang Aplikasi'));
    await tester.pumpAndSettle();

    expect(find.text('Nama Baru'), findsOneWidget);
  });

  test('versi di AppInfo sama dengan versi di pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('version: ${AppInfo.versi}+'));
  });
}
