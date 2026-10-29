import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/app/app.dart';
import 'package:profil_mahasiswa/utils/validators.dart';

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> bukaForm(WidgetTester tester) async {
  useTallScreen(tester);
  await tester.pumpWidget(const StudyLogApp());
  await tester.tap(find.text('Buat Catatan'));
  await tester.pumpAndSettle();
}

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

Finder dalamKartu(String teks) =>
    find.descendant(of: find.byType(Card), matching: find.text(teks));

void main() {
  testWidgets('M1-T1: semua field kosong -> pesan wajib diisi tampil',
      (tester) async {
    await bukaForm(tester);

    await tester.tap(find.text('Tampilkan Catatan'));
    await tester.pump();

    expect(find.text('Mata kuliah wajib diisi'), findsOneWidget);
    expect(find.text('Topik wajib diisi'), findsOneWidget);
    expect(find.text('Judul catatan wajib diisi'), findsOneWidget);
    expect(find.text('Isi catatan wajib diisi'), findsOneWidget);
    expect(find.text('Hasil input'), findsNothing);
  });

  testWidgets('M1-T2: field berisi spasi ditolak', (tester) async {
    await bukaForm(tester);
    await isiForm(tester, judul: '   ');

    await tester.tap(find.text('Tampilkan Catatan'));
    await tester.pump();

    expect(find.text('Judul catatan wajib diisi'), findsOneWidget);
    expect(find.text('Hasil input'), findsNothing);
  });

  testWidgets('Topik kurang dari 3 karakter ditolak', (tester) async {
    await bukaForm(tester);
    await isiForm(tester, topik: 'ab');

    await tester.tap(find.text('Tampilkan Catatan'));
    await tester.pump();

    expect(find.text('Topik minimal 3 karakter'), findsOneWidget);
    expect(find.text('Hasil input'), findsNothing);
  });

  testWidgets('M1-T3: semua field terisi -> Card dan SnackBar muncul',
      (tester) async {
    await bukaForm(tester);
    await isiForm(tester);

    await tester.tap(find.text('Tampilkan Catatan'));
    await tester.pump();

    expect(find.text('Hasil input'), findsOneWidget);
    expect(dalamKartu('Dasar setState'), findsOneWidget);
    expect(find.text('Data ditampilkan (belum tersimpan permanen).'),
        findsOneWidget);
    // Tombol berubah menjadi tanda berhasil.
    expect(find.text('Tersimpan Sementara'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('M1-T4: ubah judul lalu tampilkan lagi -> Card diperbarui',
      (tester) async {
    await bukaForm(tester);
    await isiForm(tester);
    await tester.tap(find.text('Tampilkan Catatan'));
    await tester.pump();
    expect(dalamKartu('Dasar setState'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(2), 'Judul baru');
    await tester.pump();
    // Mengubah input mengembalikan tombol ke keadaan awal.
    expect(find.text('Tampilkan Catatan'), findsOneWidget);

    await tester.tap(find.text('Tampilkan Catatan'));
    await tester.pump();

    expect(dalamKartu('Judul baru'), findsOneWidget);
    expect(dalamKartu('Dasar setState'), findsNothing);
  });

  testWidgets('Tombol Bersihkan mengosongkan form dan menghapus Card',
      (tester) async {
    await bukaForm(tester);
    await isiForm(tester);
    await tester.tap(find.text('Tampilkan Catatan'));
    await tester.pump();

    await tester.tap(find.text('Bersihkan'));
    await tester.pump();

    expect(find.text('Hasil input'), findsNothing);
    expect(find.text('Tampilkan Catatan'), findsOneWidget);
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
