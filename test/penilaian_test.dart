import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/data/penilaian_repository.dart';
import 'package:profil_mahasiswa/models/penilaian_dosen.dart';
import 'package:profil_mahasiswa/viewmodels/catatan_view_model.dart'
    show StatusSinkron;
import 'package:profil_mahasiswa/viewmodels/penilaian_view_model.dart';

import 'fake_server.dart';
import 'in_memory_local_store.dart';
import 'test_helpers.dart';

Map<String, int> semuaSkor(int nilai) =>
    {for (final a in aspekPenilaian) a.kode: nilai};

Map<String, Object?> barisServer(int mk, int pt, int nilai, {int id = 1}) => {
      'id': id,
      'mataKuliahId': mk,
      'pertemuan': pt,
      'skor': semuaSkor(nilai),
      'komentar': '',
      'dinilaiPada': '2026-11-19 01:09:02',
    };

void main() {
  group('model', () {
    test('rataRata dihitung dari semua aspek', () {
      final p = PenilaianDosen(
        mataKuliahId: 1,
        pertemuan: 1,
        skor: const {
          'penguasaan': 5,
          'penyampaian': 4,
          'kesesuaian': 4,
          'interaksi': 3,
          'disiplin': 4,
        },
        dinilaiPada: DateTime(2026, 11, 19),
      );
      expect(p.rataRata, closeTo(4.0, 0.0001));
    });

    test('kategoriSkor dan formatSkor', () {
      expect(kategoriSkor(4.5), 'Sangat baik');
      expect(kategoriSkor(4.0), 'Baik');
      expect(kategoriSkor(3.0), 'Cukup');
      expect(kategoriSkor(2.0), 'Kurang');
      expect(kategoriSkor(1.0), 'Sangat kurang');
      expect(formatSkor(4.25), '4,3');
      expect(formatSkor(5), '5,0');
    });

    test('toJson/fromJson bolak-balik', () {
      final p = PenilaianDosen(
        mataKuliahId: 2,
        pertemuan: 3,
        skor: semuaSkor(4),
        komentar: 'Mantap',
        dinilaiPada: DateTime(2026, 11, 19, 10),
      );
      final q = PenilaianDosen.fromJson(p.toJson());
      expect(q.mataKuliahId, 2);
      expect(q.pertemuan, 3);
      expect(q.skor, p.skor);
      expect(q.komentar, 'Mantap');
      expect(q.dinilaiPada, p.dinilaiPada);
    });

    test('fromJson membaca format tanggal server (YYYY-MM-DD HH:MM:SS)', () {
      final p = PenilaianDosen.fromJson({
        'id': 1,
        'mataKuliahId': 5,
        'pertemuan': 2,
        'skor': semuaSkor(5),
        'komentar': '',
        'dinilaiPada': '2026-11-19 01:09:02',
      });
      expect(p.dinilaiPada, DateTime(2026, 11, 19, 1, 9, 2));
    });
  });

  group('PenilaianViewModel (offline-first)', () {
    late FakeServer server;
    late InMemoryLocalStore local;
    late PenilaianViewModel vm;

    PenilaianViewModel buatVm() => PenilaianViewModel(PenilaianRepository(
        server.api, local,
        clock: () => DateTime(2026, 11, 19)));

    setUp(() {
      server = FakeServer();
      local = InMemoryLocalStore();
      vm = buatVm();
    });

    test('validateSkor menolak aspek yang belum dinilai', () {
      expect(vm.validateSkor({}), 'Semua aspek wajib dinilai');
      final sebagian = semuaSkor(4)..remove('disiplin');
      expect(vm.validateSkor(sebagian), isNotNull);
      expect(vm.validateSkor(semuaSkor(4)), isNull);
    });

    test('skor tidak lengkap ditolak dan tidak menyentuh server', () async {
      await expectLater(
        vm.simpan(mataKuliahId: 1, pertemuan: 1, skor: {}),
        throwsArgumentError,
      );
      expect(server.putPenilaianCount, 0);
      expect(vm.jumlahTerisi(1), 0);
    });

    test('simpan: langsung ada di lokal, lalu terkirim saat online', () async {
      await vm.simpan(
          mataKuliahId: 5,
          pertemuan: 1,
          skor: semuaSkor(4),
          komentar: '  bagus  ');
      expect(vm.untuk(5, 1), isNotNull); // tanpa menunggu jaringan

      await vm.sinkronkan();
      expect(server.penilaian, hasLength(1));
      expect(server.penilaian.single['komentar'], 'bagus');
      expect(vm.tertunda, 0);
      expect(vm.untuk(5, 1)!.menunggu, isFalse);
      expect(vm.status, StatusSinkron.online);
    });

    test('offline: simpan tetap berhasil, masuk antrian, terkirim nanti',
        () async {
      server.down = true;
      await vm.simpan(mataKuliahId: 5, pertemuan: 1, skor: semuaSkor(5));
      await vm.sinkronkan();

      expect(vm.status, StatusSinkron.offline);
      expect(vm.tertunda, 1);
      expect(vm.untuk(5, 1)!.menunggu, isTrue);
      expect(vm.untuk(5, 1)!.rataRata, 5);
      expect(server.penilaian, isEmpty);

      server.down = false;
      await vm.sinkronkan();
      expect(vm.status, StatusSinkron.online);
      expect(vm.tertunda, 0);
      expect(vm.untuk(5, 1)!.menunggu, isFalse);
      expect(server.penilaian, hasLength(1));
    });

    test('antrian bertahan setelah aplikasi ditutup lalu dibuka lagi',
        () async {
      server.down = true;
      await vm.simpan(mataKuliahId: 5, pertemuan: 1, skor: semuaSkor(4));
      await vm.sinkronkan();
      expect(server.penilaian, isEmpty);

      server.down = false;
      final baru = buatVm(); // repository baru, penyimpanan lokal sama
      await baru.mulai();

      expect(server.penilaian, hasLength(1));
      expect(baru.tertunda, 0);
      expect(baru.untuk(5, 1), isNotNull);
    });

    test('diubah berkali-kali saat offline: hanya kiriman terakhir terkirim',
        () async {
      server.down = true;
      await vm.simpan(mataKuliahId: 5, pertemuan: 1, skor: semuaSkor(3));
      await vm.simpan(mataKuliahId: 5, pertemuan: 1, skor: semuaSkor(5));
      await vm.sinkronkan();
      expect(vm.tertunda, 1); // satu entri per pertemuan

      server.down = false;
      await vm.sinkronkan();
      expect(server.putPenilaianCount, 1);
      expect(server.penilaian.single['skor'], equals(semuaSkor(5)));
    });

    test('hapus saat offline: hilang di lokal, di server menyusul', () async {
      await vm.simpan(mataKuliahId: 5, pertemuan: 1, skor: semuaSkor(4));
      await vm.sinkronkan();
      expect(server.penilaian, hasLength(1));

      server.down = true;
      await vm.hapus(5, 1);
      await vm.sinkronkan();
      expect(vm.untuk(5, 1), isNull);
      expect(vm.tertunda, 1);
      expect(server.penilaian, hasLength(1));

      server.down = false;
      await vm.sinkronkan();
      expect(server.penilaian, isEmpty);
      expect(vm.tertunda, 0);
    });

    test('simpan lalu hapus sebelum terkirim: server tidak menerima apa-apa',
        () async {
      server.down = true;
      await vm.simpan(mataKuliahId: 5, pertemuan: 1, skor: semuaSkor(4));
      await vm.hapus(5, 1);
      await vm.sinkronkan();

      server.down = false;
      await vm.sinkronkan();
      expect(server.putPenilaianCount, 0);
      expect(server.penilaian, isEmpty);
      expect(vm.tertunda, 0);
    });

    test('ditolak permanen oleh server: ditandai, tidak hilang, bisa diperbaiki',
        () async {
      server.tolakPenilaian = 'Mata kuliah tidak ditemukan';
      await vm.simpan(mataKuliahId: 5, pertemuan: 1, skor: semuaSkor(4));
      await vm.sinkronkan();

      expect(vm.ditolak, 1);
      expect(vm.tertunda, 1);
      expect(vm.pesanSinkron, 'Mata kuliah tidak ditemukan');
      expect(vm.status, StatusSinkron.online); // server terjangkau
      expect(vm.untuk(5, 1)!.galat, 'Mata kuliah tidak ditemukan');
      expect(vm.untuk(5, 1), isNotNull); // tidak dihapus walau server kosong

      // Server kembali menerima; menyimpan ulang mengantrikan lagi.
      server.tolakPenilaian = null;
      await vm.simpan(mataKuliahId: 5, pertemuan: 1, skor: semuaSkor(3));
      await vm.sinkronkan();
      expect(vm.ditolak, 0);
      expect(vm.tertunda, 0);
      expect(server.penilaian, hasLength(1));
    });

    test('penilaian dari perangkat lain ikut ditarik', () async {
      server.penilaian.add(barisServer(5, 3, 4));
      await vm.sinkronkan();

      expect(vm.untuk(5, 3)!.rataRata, 4);
      expect(vm.tertunda, 0);
    });

    test('dihapus di perangkat lain: ikut hilang di lokal', () async {
      server.penilaian.add(barisServer(5, 3, 4));
      await vm.sinkronkan();
      expect(vm.untuk(5, 3), isNotNull);

      server.penilaian.clear();
      await vm.sinkronkan();
      expect(vm.untuk(5, 3), isNull);
    });

    test('perubahan lokal yang tertunda menang atas data server', () async {
      server.penilaian.add(barisServer(5, 1, 5));
      await vm.sinkronkan();

      server.down = true;
      await vm.simpan(mataKuliahId: 5, pertemuan: 1, skor: semuaSkor(2));
      await vm.sinkronkan();
      expect(vm.untuk(5, 1)!.rataRata, 2);

      server.down = false;
      await vm.sinkronkan();
      expect(server.penilaian.single['skor'], equals(semuaSkor(2)));
      expect(vm.untuk(5, 1)!.rataRata, 2);
    });

    test('rataRataMatkul null saat kosong, lalu rata-rata antar pertemuan',
        () async {
      expect(vm.rataRataMatkul(1), isNull);
      await vm.simpan(mataKuliahId: 1, pertemuan: 1, skor: semuaSkor(5));
      await vm.simpan(mataKuliahId: 1, pertemuan: 2, skor: semuaSkor(3));
      await vm.simpan(mataKuliahId: 2, pertemuan: 1, skor: semuaSkor(1));

      expect(vm.rataRataMatkul(1), closeTo(4.0, 0.0001));
      expect(vm.rataRataMatkul(2), closeTo(1.0, 0.0001));
    });

    test('cache lokal rusak tidak membuat aplikasi gagal', () async {
      await local.tulisCache('penilaian_dosen', 'bukan json');
      await local.tulisCache('penilaian_antrian', '{{');

      await vm.mulai();
      expect(vm.jumlahTerisi(1), 0);
      expect(vm.tertunda, 0);
    });
  });

  group('layar', () {
    Future<void> bukaPenilaian(
      WidgetTester tester,
      FakeServer server, {
      InMemoryLocalStore? local,
    }) async {
      await bukaApp(tester, server, local: local);
      await tapTab(tester, 'Mata Kuliah');
      await tester.tap(find.text('Pemrograman Aplikasi Bergerak'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nilai Dosen'));
      await tester.pumpAndSettle();
    }

    Future<void> nilaiSemua(WidgetTester tester, int n) async {
      for (final a in aspekPenilaian) {
        await tester.tap(find.byKey(Key('skor-${a.kode}-$n')));
        await tester.pump();
      }
    }

    Future<void> tekanSimpan(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
      await tester.pumpAndSettle();
    }

    testWidgets('Simpan baru aktif setelah semua aspek dinilai', (tester) async {
      final server = FakeServer();
      await bukaPenilaian(tester, server);
      expect(find.text('Penilaian Dosen'), findsOneWidget);
      expect(find.text('Belum ada penilaian'), findsOneWidget);
      expect(find.text('0 dari 16 pertemuan dinilai'), findsOneWidget);

      await tester.tap(find.text('Pertemuan 1'));
      await tester.pumpAndSettle();
      expect(find.text('Penilaian Pertemuan 1'), findsOneWidget);

      FilledButton simpan() => tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Simpan'));
      expect(simpan().onPressed, isNull);

      // Nilai 4 aspek saja: Simpan masih nonaktif.
      for (final a in aspekPenilaian.take(4)) {
        await tester.tap(find.byKey(Key('skor-${a.kode}-5')));
        await tester.pump();
      }
      expect(simpan().onPressed, isNull);

      await tester.tap(find.byKey(Key('skor-${aspekPenilaian.last.kode}-5')));
      await tester.pump();
      expect(simpan().onPressed, isNotNull);

      await tekanSimpan(tester);

      expect(find.text('Penilaian disimpan'), findsOneWidget);
      expect(find.text('5,0 · Sangat baik'), findsOneWidget);
      expect(find.text('1 dari 16 pertemuan dinilai'), findsOneWidget);
      expect(find.text('Rata-rata 5,0 / 5 · Sangat baik'), findsOneWidget);
      expect(server.penilaian, hasLength(1));
    });

    testWidgets('offline: tersimpan dengan penanda, terkirim lewat Kirim ulang',
        (tester) async {
      final server = FakeServer();
      await bukaPenilaian(tester, server);

      server.down = true;
      await tester.tap(find.text('Pertemuan 2'));
      await tester.pumpAndSettle();
      await nilaiSemua(tester, 5);
      await tekanSimpan(tester);

      // Form menutup: penyimpanan lokal tidak menunggu jaringan.
      expect(find.text('Penilaian Pertemuan 2'), findsNothing);
      expect(find.text('Penilaian disimpan'), findsOneWidget);
      expect(find.text('5,0 · Sangat baik · menunggu dikirim'), findsOneWidget);
      expect(find.text('Offline · 1 penilaian menunggu dikirim'),
          findsOneWidget);
      expect(server.penilaian, isEmpty);

      server.down = false;
      await tester.tap(find.text('Kirim ulang'));
      await tester.pumpAndSettle();

      expect(find.text('5,0 · Sangat baik'), findsOneWidget);
      expect(find.textContaining('menunggu dikirim'), findsNothing);
      expect(find.text('Kirim ulang'), findsNothing);
      expect(server.penilaian, hasLength(1));
    });

    testWidgets('antrian offline terkirim setelah aplikasi dibuka ulang',
        (tester) async {
      final server = FakeServer();
      final local = InMemoryLocalStore();
      await bukaPenilaian(tester, server, local: local);

      server.down = true; // koneksi putus setelah layar terbuka
      await tester.tap(find.text('Pertemuan 4'));
      await tester.pumpAndSettle();
      await nilaiSemua(tester, 4);
      await tekanSimpan(tester);
      expect(server.penilaian, isEmpty);

      // "Tutup" aplikasi, server hidup lagi, lalu buka kembali.
      await tester.pumpWidget(const SizedBox());
      server.down = false;
      await bukaPenilaian(tester, server, local: local);

      expect(server.penilaian, hasLength(1));
      expect(find.text('4,0 · Baik'), findsOneWidget);
      expect(find.textContaining('menunggu dikirim'), findsNothing);
    });

    testWidgets('penilaian dari server tampil saat layar dibuka',
        (tester) async {
      final server = FakeServer()..penilaian.add(barisServer(5, 3, 4));
      await bukaPenilaian(tester, server);

      expect(find.text('4,0 · Baik'), findsOneWidget);
      expect(find.text('1 dari 16 pertemuan dinilai'), findsOneWidget);
    });
  });
}
