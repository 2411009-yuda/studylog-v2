import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/data/api_client.dart';
import 'package:profil_mahasiswa/data/catatan_repository.dart';
import 'package:profil_mahasiswa/data/mata_kuliah_repository.dart';
import 'package:profil_mahasiswa/data/sinkron_service.dart';
import 'package:profil_mahasiswa/models/catatan.dart';
import 'package:profil_mahasiswa/utils/urutan_catatan.dart';
import 'package:profil_mahasiswa/viewmodels/catatan_view_model.dart';
import 'package:profil_mahasiswa/viewmodels/mata_kuliah_view_model.dart';

import 'fake_server.dart';
import 'in_memory_local_store.dart';

Catatan baru({int mk = 5, String judul = 'Judul'}) => Catatan(
      mataKuliahId: mk,
      mataKuliahKode: '111000',
      mataKuliahNama: 'Pemrograman Aplikasi Bergerak',
      topik: 'Topik',
      judul: judul,
      isi: 'Isi',
      tanggal: DateTime(2026, 10, 30, 19, 5),
    );

void main() {
  group('CatatanViewModel', () {
    late FakeServer server;
    late InMemoryLocalStore local;
    late CatatanViewModel vm;

    setUp(() {
      server = FakeServer();
      local = InMemoryLocalStore();
      vm = CatatanViewModel(
        CatatanRepository(local),
        SinkronService(server.api, local),
      );
    });

    test('mulai: menampilkan data lokal lalu menyatukan data server', () async {
      server.seedCatatan(judul: 'Dari server');
      await vm.mulai();

      expect(vm.catatan.single.judul, 'Dari server');
      expect(vm.status, StatusSinkron.online);
      expect(vm.tertunda, 0);
      expect(vm.terakhirSinkron, isNotNull);
    });

    test('tambah: selesai tanpa menunggu server dan masuk antrian saat offline',
        () async {
      server.down = true;
      await vm.tambahCatatan(baru(judul: 'Offline'));

      // Sudah tampil dan menunggu sinkron, walau server mati.
      expect(vm.catatan.single.judul, 'Offline');
      expect(vm.catatan.single.menunggu, isTrue);
      expect(vm.tertunda, 1);
      expect(server.catatan, isEmpty);

      await vm.sinkronkan(); // bergabung dengan sinkronisasi yang sedang jalan
      expect(vm.status, StatusSinkron.offline);
      expect(vm.tertunda, 1);
    });

    test('tambah: terkirim ke server saat online', () async {
      await vm.tambahCatatan(baru(judul: 'Online'));
      await vm.sinkronkan();

      expect(server.catatan.single['judul'], 'Online');
      expect(vm.catatan.single.menunggu, isFalse);
      expect(vm.catatan.single.serverId, isNotNull);
      expect(vm.tertunda, 0);
      expect(vm.status, StatusSinkron.online);
    });

    test('antrian offline terkirim setelah server kembali', () async {
      server.down = true;
      await vm.tambahCatatan(baru(judul: 'Satu'));
      await vm.tambahCatatan(baru(judul: 'Dua'));
      await vm.sinkronkan();
      expect(vm.tertunda, 2);

      server.down = false;
      await vm.sinkronkan();

      expect(vm.tertunda, 0);
      expect(vm.status, StatusSinkron.online);
      expect(server.catatan.map((c) => c['judul']), ['Satu', 'Dua']);
    });

    test('ubah dan hapus ikut tersinkron', () async {
      await vm.tambahCatatan(baru(judul: 'Lama'));
      await vm.sinkronkan();
      final awal = vm.catatan.single;

      await vm.ubahCatatan(awal.copyWith(
        mataKuliahId: 2,
        mataKuliahKode: '110700',
        mataKuliahNama: 'Kriptografi',
        judul: 'Baru',
      ));
      await vm.sinkronkan();
      expect(server.catatan.single['judul'], 'Baru');
      expect(server.catatan.single['mataKuliahNama'], 'Kriptografi');

      await vm.hapusCatatan(vm.catatan.single.id!);
      expect(vm.catatan, isEmpty); // hilang di perangkat seketika
      await vm.sinkronkan();
      expect(server.catatan, isEmpty);
    });

    test('hapus hanya menghilangkan item terpilih', () async {
      await vm.tambahCatatan(baru(judul: 'A'));
      await vm.tambahCatatan(baru(judul: 'B'));
      await vm.sinkronkan();
      final idA = vm.catatan.firstWhere((c) => c.judul == 'A').id!;

      await vm.hapusCatatan(idA);
      await vm.sinkronkan();

      expect(vm.catatan.map((c) => c.judul), ['B']);
      expect(server.catatan.map((c) => c['judul']), ['B']);
    });

    test('urutan: default terbaru, dapat diubah, dan bertahan setelah muat ulang',
        () async {
      server
        ..seedCatatan(judul: 'Bumi', tanggal: '2026-10-28 10:00:00')
        ..seedCatatan(judul: 'Awan', tanggal: '2026-10-29 10:00:00')
        ..seedCatatan(judul: 'Cahaya', tanggal: '2026-10-30 10:00:00');
      await vm.mulai();
      expect(vm.urutan, UrutanCatatan.terbaru);
      expect(vm.catatan.map((c) => c.judul), ['Cahaya', 'Awan', 'Bumi']);

      var notified = 0;
      vm.addListener(() => notified++);
      vm.ubahUrutan(UrutanCatatan.judulAZ);
      expect(vm.catatan.map((c) => c.judul), ['Awan', 'Bumi', 'Cahaya']);
      expect(notified, 1);

      // Memilih urutan yang sama tidak memberi notifikasi.
      vm.ubahUrutan(UrutanCatatan.judulAZ);
      expect(notified, 1);

      // Muat ulang tidak mengembalikan urutan ke default.
      await vm.sinkronkan();
      expect(vm.catatan.map((c) => c.judul), ['Awan', 'Bumi', 'Cahaya']);
    });

    test('byId mengembalikan catatan atau null', () async {
      await vm.tambahCatatan(baru());
      expect(vm.byId(vm.catatan.single.id!), isNotNull);
      expect(vm.byId(999), isNull);
    });

    test('ubah tanpa id melempar ArgumentError', () async {
      await expectLater(() => vm.ubahCatatan(baru()), throwsArgumentError);
    });

    test('perubahan yang ditolak server dihitung dan tetap di antrian',
        () async {
      server.tolakKlien = 'Mata kuliah tidak ditemukan';
      await vm.tambahCatatan(baru());
      await vm.sinkronkan();

      expect(vm.status, StatusSinkron.online); // server terjangkau
      expect(vm.tertunda, 1);
      expect(vm.ditolak, 1);
      expect(vm.pesanSinkron, 'Mata kuliah tidak ditemukan');
    });
  });

  group('MataKuliahViewModel + cache offline', () {
    test('muat membaca mata kuliah dan jadwal dari server', () async {
      final server = FakeServer();
      final vm = MataKuliahViewModel(
        MataKuliahRepository(server.api, InMemoryLocalStore()),
        clock: () => DateTime(2026, 10, 30, 20, 40),
      );
      await vm.muat();

      expect(vm.courses, hasLength(8));
      expect(vm.totalSks, 23);
      expect(vm.jadwal, hasLength(8));
      expect(vm.dariCache, isFalse);
      expect(vm.courseByKode('111000')?.nama, 'Pemrograman Aplikasi Bergerak');
      expect(vm.courseById(2)?.nama, 'Kriptografi');
      expect(vm.jadwalUntuk(5).single.label, 'Jumat 20:30–22:00');
      expect(vm.jadwalUntukCatatanBaru()?.mataKuliahId, 5);
      expect(vm.jadwalTerdekat()?.berlangsung, isTrue);
    });

    test('server mati + cache ada -> data dari cache', () async {
      final server = FakeServer();
      final local = InMemoryLocalStore();
      await MataKuliahViewModel(MataKuliahRepository(server.api, local)).muat();

      server.down = true;
      final vm = MataKuliahViewModel(MataKuliahRepository(server.api, local));
      await vm.muat();

      expect(vm.error, isNull);
      expect(vm.dariCache, isTrue);
      expect(vm.courses, hasLength(8));
      expect(vm.jadwal, hasLength(8));
    });

    test('server mati + belum ada cache -> error', () async {
      final server = FakeServer()..down = true;
      final vm = MataKuliahViewModel(
        MataKuliahRepository(server.api, InMemoryLocalStore()),
      );
      await vm.muat();

      expect(vm.error, contains('Tidak dapat memuat mata kuliah'));
      expect(vm.courses, isEmpty);
    });

    test('kembali online setelah memakai cache -> dariCache false', () async {
      final server = FakeServer();
      final local = InMemoryLocalStore();
      final vm = MataKuliahViewModel(MataKuliahRepository(server.api, local));
      await vm.muat();
      server.down = true;
      await vm.muat();
      expect(vm.dariCache, isTrue);

      server.down = false;
      await vm.muat();
      expect(vm.dariCache, isFalse);
    });
  });

  group('ApiClient', () {
    test('respons error dibaca sebagai ApiException lengkap dengan status',
        () async {
      final api = FakeServer().api;
      await expectLater(
        () => api.get('/api/tidak-ada'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)),
      );
    });

    test('server mati -> ApiException tanpa status (kegagalan sementara)',
        () async {
      final api = (FakeServer()..down = true).api;
      await expectLater(
        () => api.get('/api/catatan'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', isNull)),
      );
    });

    test('pesanError', () {
      expect(pesanError(const ApiException('x')), 'x');
      expect(pesanError(StateError('y')), contains('y'));
    });
  });
}
