import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/app/app.dart';

/// Layar uji bawaan hanya 800x600, sehingga tombol di bagian bawah layar
/// berada di luar jangkauan tap. Layar yang lebih tinggi memuat semua konten.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('Beranda -> Profil -> kembali mengikuti back stack',
          (tester) async {
        useTallScreen(tester);
        await tester.pumpWidget(const StudyLogApp());
        expect(find.text('StudyLog'), findsOneWidget);

        await tester.tap(find.text('Profil'));
        await tester.pumpAndSettle();
        expect(find.text('NIM'), findsOneWidget);
        expect(find.text('2411009'), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('StudyLog'), findsOneWidget);
      });

  testWidgets('Beranda -> Mata Kuliah -> Detail mengirim id lewat route',
          (tester) async {
        useTallScreen(tester);
        await tester.pumpWidget(const StudyLogApp());

        await tester.tap(find.text('Mata Kuliah'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pemrograman Aplikasi Bergerak'));
        await tester.pumpAndSettle();
        expect(find.text('Detail Mata Kuliah'), findsOneWidget);
        expect(find.text('Prasyarat'), findsOneWidget);
        expect(find.text('Algoritme dan Pemrograman'), findsOneWidget);

        // Back stack: Detail -> Daftar Mata Kuliah -> Beranda.
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('8 mata kuliah · 23 SKS'), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('StudyLog'), findsOneWidget);
      });

  testWidgets('Beranda -> Kontak menampilkan email, web, dan GitHub',
          (tester) async {
        useTallScreen(tester);
        await tester.pumpWidget(const StudyLogApp());

        await tester.tap(find.text('Kontak'));
        await tester.pumpAndSettle();

        expect(find.text('2411009@students.universitasmulia.ac.id'),
            findsOneWidget);
        expect(find.text('https://yuda-pratama.web.id/'), findsOneWidget);
        expect(find.text('https://github.com/2411009-yuda'), findsOneWidget);
      });

  testWidgets('state di ViewModel bertahan saat pindah layar dan rotasi',
          (tester) async {
        useTallScreen(tester);
        await tester.pumpWidget(const StudyLogApp());

        // Buka Profil dan ubah nama lewat dialog.
        await tester.tap(find.text('Profil'));
        await tester.pumpAndSettle();
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

        // Kembali ke Beranda: nama baru tampil di kartu sambutan.
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Yuda Pratama Putra'), findsOneWidget);
      });

  testWidgets('tombol Simpan nonaktif saat input tidak valid', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const StudyLogApp());

    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
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