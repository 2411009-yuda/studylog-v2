import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/app/app.dart';

import 'test_helpers.dart';

void main() {
  testWidgets('Bottom nav: Beranda -> Profil -> Beranda', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const StudyLogApp());
    expect(find.text('StudyLog'), findsOneWidget);

    await tapTab(tester, 'Profil');
    expect(find.text('NIM'), findsOneWidget);
    expect(find.text('2411009'), findsOneWidget);

    await tapTab(tester, 'Beranda');
    expect(find.text('StudyLog'), findsOneWidget);
  });

  testWidgets('Tab Mata Kuliah -> Detail mengirim id lewat route',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const StudyLogApp());

    await tapTab(tester, 'Mata Kuliah');
    await tester.tap(find.text('Pemrograman Aplikasi Bergerak'));
    await tester.pumpAndSettle();
    expect(find.text('Detail Mata Kuliah'), findsOneWidget);
    expect(find.text('Prasyarat'), findsOneWidget);
    expect(find.text('Algoritme dan Pemrograman'), findsOneWidget);

    // Kembali ke daftar mata kuliah (tab tetap Mata Kuliah).
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('8 mata kuliah · 23 SKS'), findsOneWidget);
  });

  testWidgets('Tab Kontak menampilkan email, web, dan GitHub', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const StudyLogApp());

    await tapTab(tester, 'Kontak');

    expect(find.text('2411009@students.universitasmulia.ac.id'),
        findsOneWidget);
    expect(find.text('https://yuda-pratama.web.id/'), findsOneWidget);
    expect(find.text('https://github.com/2411009-yuda'), findsOneWidget);
  });

  testWidgets('tombol kembali pada tab lain mengarah ke Beranda',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const StudyLogApp());
    await tapTab(tester, 'Kontak');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.selectedIndex, 0);
  });

  testWidgets('state profil bertahan saat pindah tab dan rotasi',
      (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const StudyLogApp());

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
    useTallScreen(tester);
    await tester.pumpWidget(const StudyLogApp());

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
