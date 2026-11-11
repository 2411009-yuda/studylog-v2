import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/utils/validators.dart';

import 'fake_server.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('form terbaru memiliki dropdown dan tiga field teks',
      (tester) async {
    await bukaApp(tester, FakeServer());
    await tapPlus(tester);

    expect(find.text('Tambah Catatan'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(find.text('Simpan'), findsOneWidget);
  });

  testWidgets('semua field kosong ditolak dengan validasi', (tester) async {
    final server = FakeServer();
    // Sabtu: tidak ada jadwal, jadi mata kuliah tidak terisi otomatis.
    await bukaApp(tester, server, sekarang: sabtuPagi);
    await tapPlus(tester);

    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Mata kuliah wajib dipilih'), findsOneWidget);
    expect(find.text('Topik wajib diisi'), findsOneWidget);
    expect(find.text('Judul catatan wajib diisi'), findsOneWidget);
    expect(find.text('Isi catatan wajib diisi'), findsOneWidget);
    expect(find.text('Catatan sudah dibuat'), findsNothing);
    expect(server.catatan, isEmpty);
  });

  testWidgets('field berisi spasi ditolak', (tester) async {
    final server = FakeServer();
    await bukaApp(tester, server);
    await tapPlus(tester);
    await isiForm(tester, judul: '   ');

    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Judul catatan wajib diisi'), findsOneWidget);
    expect(find.text('Catatan sudah dibuat'), findsNothing);
    expect(server.catatan, isEmpty);
  });

  testWidgets('topik kurang dari tiga karakter ditolak', (tester) async {
    final server = FakeServer();
    await bukaApp(tester, server);
    await tapPlus(tester);
    await isiForm(tester, topik: 'ab');

    await tester.tap(find.text('Simpan'));
    await tester.pump();

    expect(find.text('Topik minimal 3 karakter'), findsOneWidget);
    expect(find.text('Catatan sudah dibuat'), findsNothing);
    expect(server.catatan, isEmpty);
  });

  testWidgets('catatan valid disimpan dan tampil pada daftar', (tester) async {
    final server = FakeServer();
    await bukaApp(tester, server);
    await tapPlus(tester);
    await isiForm(tester);

    await simpanTambah(tester); // pop-up -> "Tidak": menuju Daftar Catatan

    expect(find.text('Daftar Catatan'), findsOneWidget);
    expect(find.text('Dasar setState'), findsOneWidget);
    expect(find.text('Total: 1 catatan'), findsOneWidget);
    expect(server.catatan.single['judul'], 'Dasar setState');
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
