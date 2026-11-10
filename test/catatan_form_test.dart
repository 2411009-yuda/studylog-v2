import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/utils/validators.dart';

import 'fake_server.dart';
import 'test_helpers.dart';

Future<void> bukaForm(WidgetTester tester, {DateTime? sekarang}) async {
  await bukaApp(tester, FakeServer(), sekarang: sekarang);
  await tapPlus(tester);
}

Future<void> pilihMataKuliah(WidgetTester tester) async {
  final dropdown = find.byType(DropdownButtonFormField<int>);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pemrograman Aplikasi Bergerak').last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('form terbaru memiliki dropdown dan tiga field teks', (tester) async {
    await bukaForm(tester);

    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Tambah Catatan'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);
    expect(find.text('Tampilkan Catatan'), findsNothing);
  });

  testWidgets('semua field kosong ditolak dengan validasi', (tester) async {
    await bukaForm(tester, sekarang: sabtuPagi);

    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Mata kuliah wajib dipilih'), findsOneWidget);
    expect(find.text('Topik wajib diisi'), findsOneWidget);
    expect(find.text('Judul catatan wajib diisi'), findsOneWidget);
    expect(find.text('Isi catatan wajib diisi'), findsOneWidget);
  });

  testWidgets('topik kurang dari tiga karakter ditolak', (tester) async {
    await bukaForm(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'ab');
    await tester.enterText(find.byType(TextFormField).at(1), 'Judul valid');
    await tester.enterText(find.byType(TextFormField).at(2), 'Isi valid');
    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Topik minimal 3 karakter'), findsOneWidget);
    expect(find.text('Tambah Catatan'), findsOneWidget);
  });

  testWidgets('catatan valid disimpan dan tampil pada daftar', (tester) async {
    final server = FakeServer();
    await bukaApp(tester, server);
    await tapPlus(tester);
    await pilihMataKuliah(tester);
    await isiForm(tester);

    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(server.catatan, hasLength(1));
    expect(server.catatan.single['judul'], 'Dasar setState');
    expect(find.textContaining('Catatan disimpan di perangkat'), findsOneWidget);

    await tester.tap(find.text('Lihat Catatan'));
    await tester.pumpAndSettle();
    expect(find.text('Dasar setState'), findsOneWidget);
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
