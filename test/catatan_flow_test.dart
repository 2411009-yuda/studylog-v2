import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/utils/validators.dart';

import 'fake_server.dart';
import 'test_helpers.dart';

Future<void> bukaDaftar(WidgetTester tester) async {
  await tester.tap(find.text('Lihat Catatan'));
  await tester.pumpAndSettle();
}

Future<void> simpanForm(WidgetTester tester) async {
  await tester.tap(find.text('Simpan'));
  await tester.pumpAndSettle();
}

void main() {
  group('Tombol + dan jadwal otomatis', () {
    testWidgets('Jumat 20:40: mata kuliah terisi otomatis dari jadwal',
        (tester) async {
      await bukaApp(tester, FakeServer());
      await tapPlus(tester);

      expect(find.text('Tambah Catatan'), findsOneWidget);
      // Nilai dropdown = id mata kuliah Pemrograman Aplikasi Bergerak (5).
      expect(
        tester.widget<DropdownButton<int>>(find.byType(DropdownButton<int>)).value,
        5,
      );
      expect(find.textContaining('Terisi otomatis dari jadwal: Jumat 20:30–22:00'),
          findsOneWidget);
    });

    testWidgets('Sabtu: tidak ada jadwal, mata kuliah dipilih manual',
        (tester) async {
      await bukaApp(tester, FakeServer(), sekarang: sabtuPagi);
      await tapPlus(tester);

      expect(find.textContaining('Terisi otomatis'), findsNothing);

      // Tanpa memilih mata kuliah, form ditolak.
      await isiForm(tester);
      await simpanForm(tester);
      expect(find.text('Mata kuliah wajib dipilih'), findsOneWidget);
      expect(find.text('Tambah Catatan'), findsOneWidget);

      // Pilih manual dari dropdown.
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kriptografi').last);
      await tester.pumpAndSettle();
      expect(find.text('Mata kuliah wajib dipilih'), findsNothing);
    });

    testWidgets('mata kuliah otomatis dapat diganti pengguna', (tester) async {
      final server = FakeServer();
      await bukaApp(tester, server);
      await tapPlus(tester);

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kriptografi').last);
      await tester.pumpAndSettle();
      // Petunjuk "otomatis" hilang karena pilihan sudah berbeda dari jadwal.
      expect(find.textContaining('Terisi otomatis'), findsNothing);

      await isiForm(tester);
      await simpanForm(tester);
      expect(server.catatan.single['mataKuliahNama'], 'Kriptografi');
    });
  });

  group('CRUD (T1-T7)', () {
    testWidgets('Daftar kosong menampilkan empty state', (tester) async {
      await bukaApp(tester, FakeServer());
      await bukaDaftar(tester);

      expect(find.text('Daftar Catatan'), findsOneWidget);
      expect(find.textContaining('Belum ada catatan'), findsOneWidget);
    });

    testWidgets('T7: form kosong menampilkan validasi dan tidak menyimpan',
        (tester) async {
      final server = FakeServer();
      await bukaApp(tester, server, sekarang: sabtuPagi);
      await tapPlus(tester);

      await simpanForm(tester);

      expect(find.text('Mata kuliah wajib dipilih'), findsOneWidget);
      expect(find.text('Topik wajib diisi'), findsOneWidget);
      expect(find.text('Judul catatan wajib diisi'), findsOneWidget);
      expect(find.text('Isi catatan wajib diisi'), findsOneWidget);
      expect(server.catatan, isEmpty);
    });

    testWidgets('T1 Create: simpan menulis ke database dan muncul di daftar',
        (tester) async {
      final server = FakeServer();
      await bukaApp(tester, server);
      await tapPlus(tester);
      await isiForm(tester);
      await simpanForm(tester);

      // Form tertutup, kembali ke Beranda dengan jumlah terbaru.
      expect(find.text('StudyLog'), findsOneWidget);
      expect(find.text('1 catatan tersimpan di database.'), findsOneWidget);
      expect(server.catatan.single['judul'], 'Dasar setState');

      await bukaDaftar(tester);
      expect(find.text('Dasar setState'), findsOneWidget);
      expect(find.text('Total: 1 catatan'), findsOneWidget);
    });

    testWidgets('T2 Read + back stack: Detail -> Daftar -> Beranda',
        (tester) async {
      final server = FakeServer()..seedCatatan();
      await bukaApp(tester, server);
      await bukaDaftar(tester);

      await tester.tap(find.text('Dasar setState'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Catatan'), findsOneWidget);
      expect(find.text('setState memicu build ulang.'), findsOneWidget);
      expect(find.text('Topik: State'), findsOneWidget);
      expect(find.text('Dibuat: 30/10/2026 20:40'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Daftar Catatan'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('StudyLog'), findsOneWidget);
    });

    testWidgets('T3 Update: ubah judul lalu detail menampilkan data terbaru',
        (tester) async {
      final server = FakeServer()..seedCatatan();
      await bukaApp(tester, server);
      await bukaDaftar(tester);
      await tester.tap(find.text('Dasar setState'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ubah'));
      await tester.pumpAndSettle();
      expect(find.text('Ubah Catatan'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(1), 'Judul diubah');
      await tester.pump();
      await simpanForm(tester);

      expect(find.text('Detail Catatan'), findsOneWidget);
      expect(find.text('Judul diubah'), findsOneWidget);
      expect(server.catatan.single['judul'], 'Judul diubah');
    });

    testWidgets('T4 Delete batal: item tidak dihapus', (tester) async {
      final server = FakeServer()..seedCatatan();
      await bukaApp(tester, server);
      await bukaDaftar(tester);
      await tester.tap(find.text('Dasar setState'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus catatan?'), findsOneWidget);

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(server.catatan, hasLength(1));
      expect(find.text('Detail Catatan'), findsOneWidget);
    });

    testWidgets('T5 Delete setuju: hanya item terpilih yang hilang',
        (tester) async {
      final server = FakeServer()
        ..seedCatatan(judul: 'Catatan A')
        ..seedCatatan(judul: 'Catatan B');
      await bukaApp(tester, server);
      await bukaDaftar(tester);

      await tester.tap(find.text('Catatan A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus').last);
      await tester.pumpAndSettle();

      expect(find.text('Daftar Catatan'), findsOneWidget);
      expect(find.text('Catatan A'), findsNothing);
      expect(find.text('Catatan B'), findsOneWidget);
      expect(server.catatan.map((c) => c['judul']), ['Catatan B']);
    });

    testWidgets('T6 Persistence: aplikasi dibuka ulang, data masih ada',
        (tester) async {
      final server = FakeServer();
      await bukaApp(tester, server);
      await tapPlus(tester);
      await isiForm(tester);
      await simpanForm(tester);

      // "Tutup" aplikasi: bongkar widget tree. Database (server) tetap ada.
      await tester.pumpWidget(const SizedBox());
      await bukaApp(tester, server);

      expect(find.text('1 catatan tersimpan di database.'), findsOneWidget);
      await bukaDaftar(tester);
      expect(find.text('Dasar setState'), findsOneWidget);
    });
  });

  group('Gangguan koneksi', () {
    testWidgets('server mati -> pesan error dan Coba lagi memulihkan',
        (tester) async {
      final server = FakeServer()
        ..seedCatatan()
        ..down = true;
      await bukaApp(tester, server);
      await bukaDaftar(tester);

      expect(find.textContaining('Tidak dapat membaca catatan'), findsOneWidget);

      server.down = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Dasar setState'), findsOneWidget);
    });

    testWidgets('simpan saat server mati -> SnackBar gagal, form tetap terbuka',
        (tester) async {
      final server = FakeServer();
      await bukaApp(tester, server);
      await tapPlus(tester);
      await isiForm(tester);

      server.down = true;
      await simpanForm(tester);

      expect(find.textContaining('Gagal menyimpan'), findsOneWidget);
      expect(find.text('Tambah Catatan'), findsOneWidget);
      // Isian pengguna tidak hilang.
      expect(find.text('Dasar setState'), findsOneWidget);
    });
  });

  testWidgets('Beranda menampilkan kelas yang sedang berlangsung',
      (tester) async {
    await bukaApp(tester, FakeServer());

    expect(find.text('Sedang berlangsung'), findsOneWidget);
    expect(find.text('Pemrograman Aplikasi Bergerak'), findsOneWidget);
  });

  testWidgets('data bertahan saat rotasi', (tester) async {
    final server = FakeServer()..seedCatatan();
    await bukaApp(tester, server);
    await bukaDaftar(tester);

    tester.view.physicalSize = const Size(900, 400);
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
