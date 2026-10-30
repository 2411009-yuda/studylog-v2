import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/data/api_client.dart';
import 'package:profil_mahasiswa/data/catatan_repository.dart';
import 'package:profil_mahasiswa/data/mata_kuliah_repository.dart';
import 'package:profil_mahasiswa/models/catatan.dart';
import 'package:profil_mahasiswa/viewmodels/catatan_view_model.dart';
import 'package:profil_mahasiswa/viewmodels/mata_kuliah_view_model.dart';

import 'fake_server.dart';

Catatan baru({int mk = 5, String judul = 'Judul'}) => Catatan(
      mataKuliahId: mk,
      topik: 'Topik',
      judul: judul,
      isi: 'Isi',
      tanggal: DateTime(2026, 10, 30),
    );

void main() {
  group('CatatanViewModel', () {
    late FakeServer server;
    late CatatanViewModel vm;

    setUp(() {
      server = FakeServer();
      vm = CatatanViewModel(CatatanRepository(server.api));
    });

    test('muatCatatan membaca data server dan memberi notifikasi', () async {
      server.seedCatatan(judul: 'Satu');
      var notified = 0;
      vm.addListener(() => notified++);

      await vm.muatCatatan();

      expect(vm.catatan.single.judul, 'Satu');
      expect(vm.isLoading, isFalse);
      expect(vm.error, isNull);
      expect(notified, 2); // mulai memuat + selesai
    });

    test('tambah -> data tersimpan di server dan daftar dimuat ulang',
        () async {
      await vm.tambahCatatan(baru(judul: 'Baru'));

      expect(server.catatan, hasLength(1));
      expect(vm.catatan.single.judul, 'Baru');
      expect(vm.catatan.single.mataKuliahNama, 'Pemrograman Aplikasi Bergerak');
    });

    test('ubah memperbarui data', () async {
      await vm.tambahCatatan(baru(judul: 'Lama'));
      final lama = vm.catatan.single;

      await vm.ubahCatatan(Catatan(
        id: lama.id,
        mataKuliahId: 2,
        topik: 'Cipher',
        judul: 'Baru',
        isi: 'Isi baru',
        tanggal: lama.tanggal,
      ));

      expect(vm.catatan.single.judul, 'Baru');
      expect(vm.catatan.single.mataKuliahNama, 'Kriptografi');
    });

    test('hapus menghilangkan hanya item terpilih', () async {
      await vm.tambahCatatan(baru(judul: 'A'));
      await vm.tambahCatatan(baru(judul: 'B'));
      final idA = vm.catatan.firstWhere((c) => c.judul == 'A').id!;

      await vm.hapusCatatan(idA);

      expect(vm.catatan.map((c) => c.judul), ['B']);
    });

    test('byId mengembalikan catatan atau null', () async {
      await vm.tambahCatatan(baru());
      expect(vm.byId(vm.catatan.single.id!), isNotNull);
      expect(vm.byId(999), isNull);
    });

    test('server mati -> error terisi dan isLoading kembali false', () async {
      server.down = true;
      await vm.muatCatatan();

      expect(vm.error, contains('Tidak dapat membaca catatan'));
      expect(vm.isLoading, isFalse);
    });

    test('tambah gagal validasi server -> ApiException dengan pesan server',
        () async {
      final salah = Catatan(
        mataKuliahId: 5,
        topik: 'ab',
        judul: 'J',
        isi: 'I',
        tanggal: DateTime(2026, 10, 30),
      );
      await expectLater(
        () => vm.tambahCatatan(salah),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'message', 'Topik minimal 3 karakter')
            .having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('ubah tanpa id melempar ArgumentError', () async {
      await expectLater(() => vm.ubahCatatan(baru()), throwsArgumentError);
    });
  });

  group('MataKuliahViewModel', () {
    test('muat membaca mata kuliah dan jadwal', () async {
      final vm = MataKuliahViewModel(
        MataKuliahRepository(FakeServer().api),
        clock: () => DateTime(2026, 10, 30, 20, 40),
      );
      await vm.muat();

      expect(vm.courses, hasLength(8));
      expect(vm.totalSks, 23);
      expect(vm.jadwal, hasLength(8));
      expect(vm.courseByKode('111000')?.nama, 'Pemrograman Aplikasi Bergerak');
      expect(vm.courseById(2)?.nama, 'Kriptografi');
      expect(vm.jadwalUntuk(5).single.label, 'Jumat 20:30–22:00');
      expect(vm.jadwalUntukCatatanBaru()?.mataKuliahId, 5);
      expect(vm.jadwalTerdekat()?.berlangsung, isTrue);
    });

    test('server mati -> error terisi', () async {
      final server = FakeServer()..down = true;
      final vm = MataKuliahViewModel(MataKuliahRepository(server.api));
      await vm.muat();

      expect(vm.error, contains('Tidak dapat memuat mata kuliah'));
      expect(vm.courses, isEmpty);
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

    test('pesanError', () {
      expect(pesanError(const ApiException('x')), 'x');
      expect(pesanError(StateError('y')), contains('y'));
    });
  });
}
