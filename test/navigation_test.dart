import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('Bottom bar: Beranda -> Profil -> Beranda', (tester) async {
    await bukaApp(tester, FakeServer());
    expect(find.text('StudyLog'), findsOneWidget);

    await tapTab(tester, 'Profil');
    expect(find.text('NIM'), findsOneWidget);
    expect(find.text('2411009'), findsOneWidget);

    await tapTab(tester, 'Beranda');
    expect(find.text('StudyLog'), findsOneWidget);
  });

  testWidgets('Tab Mata Kuliah memuat data dari server -> Detail',
      (tester) async {
    await bukaApp(tester, FakeServer());

    await tapTab(tester, 'Mata Kuliah');
    expect(find.text('8 mata kuliah · 23 SKS'), findsOneWidget);

    await tester.tap(find.text('Pemrograman Aplikasi Bergerak'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Mata Kuliah'), findsOneWidget);
    expect(find.text('Prasyarat'), findsOneWidget);
    expect(find.text('Algoritme dan Pemrograman'), findsOneWidget);
    // Dosen dan jadwal berasal dari tabel mata_kuliah dan jadwal.
    expect(find.text('PRAMUDYA PRIMA INSAN, S.Kom., M.Kom.'), findsOneWidget);
    expect(find.textContaining('Jumat 20:30–22:00'), findsOneWidget);

    // Kembali ke daftar mata kuliah (tab tetap Mata Kuliah).
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('8 mata kuliah · 23 SKS'), findsOneWidget);
  });

  testWidgets('Tab Mata Kuliah menampilkan error + Coba lagi saat server mati',
      (tester) async {
    final server = FakeServer()..down = true;
    await bukaApp(tester, server);
    await tapTab(tester, 'Mata Kuliah');

    expect(find.textContaining('Tidak dapat memuat mata kuliah'),
        findsOneWidget);

    server.down = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.text('8 mata kuliah · 23 SKS'), findsOneWidget);
  });

  testWidgets('Tab Kontak menampilkan email, web, dan GitHub', (tester) async {
    await bukaApp(tester, FakeServer());

    await tapTab(tester, 'Kontak');

    expect(find.text('2411009@students.universitasmulia.ac.id'),
        findsOneWidget);
    expect(find.text('https://yuda-pratama.web.id/'), findsOneWidget);
    expect(find.text('https://github.com/2411009-yuda'), findsOneWidget);
  });

  testWidgets('tombol kembali pada tab lain mengarah ke Beranda',
      (tester) async {
    await bukaApp(tester, FakeServer());
    await tapTab(tester, 'Kontak');
    expect(find.text('StudyLog'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('StudyLog'), findsOneWidget);
  });

  testWidgets('state profil bertahan saat pindah tab dan rotasi',
      (tester) async {
    await bukaApp(tester, FakeServer());

    await tapTab(tester, 'Profil');
    await tester.tap(find.text('Edit Profil'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextFormField).first, 'Yuda Pratama Putra');
    await tester.pump();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Yuda Pratama Putra'), findsOneWidget);

    // Rotasi ke landscape: data tetap ada.
    tester.view.physicalSize = const Size(900, 400);
    await tester.pumpAndSettle();
    expect(find.text('Yuda Pratama Putra'), findsOneWidget);

    // Pindah ke Beranda: nama baru tampil di kartu sambutan.
    await tapTab(tester, 'Beranda');
    expect(find.text('Yuda Pratama Putra'), findsOneWidget);
  });

  testWidgets('tombol Simpan nonaktif saat input tidak valid', (tester) async {
    await bukaApp(tester, FakeServer());

    await tapTab(tester, 'Profil');
    await tester.tap(find.text('Edit Profil'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.pump();

    expect(find.text('Nama wajib diisi'), findsOneWidget);
    final simpan = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Simpan'),
    );
    expect(simpan.onPressed, isNull);
  });
}
