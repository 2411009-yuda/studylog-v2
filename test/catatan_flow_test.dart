import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/app/app.dart';
import 'package:profil_mahasiswa/utils/validators.dart';
import 'package:profil_mahasiswa/viewmodels/catatan_store.dart';

import 'test_helpers.dart';

/// Urutan field: 0 mata kuliah, 1 topik, 2 judul, 3 isi.
Future<void> isiForm(
  WidgetTester tester, {
  String mk = 'Pemrograman Mobile',
  String topik = 'State',
  String judul = 'Dasar setState',
  String isi = 'setState memicu build ulang.',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), mk);
  await tester.enterText(fields.at(1), topik);
  await tester.enterText(fields.at(2), judul);
  await tester.enterText(fields.at(3), isi);
  await tester.pump();
}

Future<void> bukaDaftar(WidgetTester tester) async {
  useTallScreen(tester);
  await tester.pumpWidget(const StudyLogApp());
  await tester.tap(find.text('Lihat Catatan'));
  await tester.pumpAndSettle();
}

Future<void> tambahSatuCatatan(WidgetTester tester) async {
  await tester.tap(find.text('Tambah'));
  await tester.pumpAndSettle();
  await isiForm(tester);
  await tester.tap(find.text('Simpan Sementara'));
  await tester.pumpAndSettle();
}

void main() {
  group('Alur M2', () {
    testWidgets('Daftar kosong menampilkan empty state', (tester) async {
      await bukaDaftar(tester);
      expect(find.text('Daftar Catatan'), findsOneWidget);
      expect(find.textContaining('Belum ada catatan'), findsOneWidget);
    });

    testWidgets('form kosong menampilkan pesan validasi dan tidak menutup',
        (tester) async {
      await bukaDaftar(tester);
      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Simpan Sementara'));
      await tester.pump();

      expect(find.text('Mata kuliah wajib diisi'), findsOneWidget);
      expect(find.text('Topik wajib diisi'), findsOneWidget);
      expect(find.text('Judul catatan wajib diisi'), findsOneWidget);
      expect(find.text('Isi catatan wajib diisi'), findsOneWidget);
      expect(find.text('Tambah Catatan'), findsOneWidget);
    });

    testWidgets('simpan menutup form dan catatan langsung muncul di daftar',
        (tester) async {
      await bukaDaftar(tester);
      await tambahSatuCatatan(tester);

      expect(find.text('Daftar Catatan'), findsOneWidget);
      expect(find.text('Dasar setState'), findsOneWidget);
      expect(find.text('Total: 1 catatan'), findsOneWidget);
      expect(find.text('Catatan disimpan sementara di memori.'),
          findsWidgets);
    });

    testWidgets('back stack: Detail -> Daftar -> Beranda', (tester) async {
      await bukaDaftar(tester);
      await tambahSatuCatatan(tester);

      await tester.tap(find.text('Dasar setState'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Catatan'), findsOneWidget);
      expect(find.text('setState memicu build ulang.'), findsOneWidget);
      expect(find.text('Topik: State'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Daftar Catatan'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('StudyLog'), findsOneWidget);
      expect(find.text('1 catatan (disimpan sementara di memori).'),
          findsOneWidget);
    });

    testWidgets('data bertahan saat rotasi', (tester) async {
      await bukaDaftar(tester);
      await tambahSatuCatatan(tester);

      tester.view.physicalSize = const Size(900, 400);
      await tester.pumpAndSettle();

      expect(find.text('Dasar setState'), findsOneWidget);
    });
  });

  group('CatatanStore', () {
    CatatanStore buat() => CatatanStore();

    void tambah(CatatanStore s, String judul) => s.tambah(
          mataKuliah: 'PAB',
          topik: 'Topik',
          judul: judul,
          isi: 'Isi',
        );

    test('tambah memberi id berurutan, terbaru di atas, dan notifikasi', () {
      final store = buat();
      var notified = 0;
      store.addListener(() => notified++);

      tambah(store, 'Pertama');
      tambah(store, 'Kedua');

      expect(store.jumlah, 2);
      expect(store.data.first.judul, 'Kedua');
      expect(store.data.first.id, 2);
      expect(store.data.last.id, 1);
      expect(notified, 2);
    });

    test('tambah merapikan spasi', () {
      final store = buat();
      store.tambah(
        mataKuliah: '  PAB ',
        topik: ' State ',
        judul: ' J ',
        isi: ' I ',
      );
      final c = store.data.single;
      expect([c.mataKuliah, c.topik, c.judul, c.isi], ['PAB', 'State', 'J', 'I']);
    });

    test('data tidak dapat dimodifikasi dari luar', () {
      final store = buat();
      tambah(store, 'A');
      expect(() => store.data.clear(), throwsUnsupportedError);
    });

    test('byId mengembalikan catatan yang tepat atau null', () {
      final store = buat();
      tambah(store, 'A');
      expect(store.byId(1)?.judul, 'A');
      expect(store.byId(99), isNull);
    });
  });

  group('validators', () {
    test('validateWajibIsi', () {
      expect(validateWajibIsi(null, 'Judul'), 'Judul wajib diisi');
      expect(validateWajibIsi('  ', 'Judul'), 'Judul wajib diisi');
      expect(validateWajibIsi('ok', 'Judul'), isNull);
    });

    test('validateTopik minimal tiga karakter', () {
      expect(validateTopik(''), isNotNull);
      expect(validateTopik('  ab '), 'Topik minimal 3 karakter');
      expect(validateTopik('abc'), isNull);
    });
  });
}
