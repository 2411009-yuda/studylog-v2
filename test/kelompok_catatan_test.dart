import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/data/catatan_repository.dart';
import 'package:profil_mahasiswa/data/sinkron_service.dart';
import 'package:profil_mahasiswa/models/catatan.dart';
import 'package:profil_mahasiswa/utils/kelompok_catatan.dart';
import 'package:profil_mahasiswa/utils/urutan_catatan.dart';
import 'package:profil_mahasiswa/viewmodels/catatan_view_model.dart';

import 'fake_server.dart';
import 'in_memory_local_store.dart';

Catatan c(int? id, String judul, int mk, String namaMk,
        {String topik = 'Umum'}) =>
    Catatan(
      id: id,
      mataKuliahId: mk,
      mataKuliahKode: 'K$mk',
      mataKuliahNama: namaMk,
      topik: topik,
      judul: judul,
      isi: 'isi',
      tanggal: DateTime(2026, 10, 30, 10).add(Duration(days: id ?? 0)),
    );

void main() {
  final pab1 = c(1, 'State', 5, 'Pemrograman Aplikasi Bergerak');
  final bd = c(2, 'Normalisasi', 7, 'Basis Data');
  final pab2 = c(3, 'Git', 5, 'Pemrograman Aplikasi Bergerak');
  final semua = [pab1, bd, pab2];

  group('utilitas kelompok', () {
    test('ringkasMataKuliah: unik, ada jumlah, urut nama A-Z', () {
      final r = ringkasMataKuliah(semua);
      expect(r.map((e) => e.nama), ['Basis Data', 'Pemrograman Aplikasi Bergerak']);
      expect(r.map((e) => e.jumlah), [1, 2]);
    });

    test('filterMataKuliah: id tertentu dan null', () {
      expect(filterMataKuliah(semua, 5), [pab1, pab2]);
      expect(filterMataKuliah(semua, null), semua);
      expect(filterMataKuliah(semua, 99), isEmpty);
    });

    test('kelompokkanPerMataKuliah: urutan di dalam kelompok dipertahankan', () {
      final k = kelompokkanPerMataKuliah([pab2, bd, pab1]);
      expect(k.map((e) => e.mataKuliah.id), [7, 5]);
      expect(k[1].catatan, [pab2, pab1]);
      expect(k.expand((e) => e.catatan).length, 3); // tidak ada yang hilang
    });
  });

  group('CatatanViewModel filter & kelompok', () {
    late CatatanViewModel vm;

    setUp(() async {
      final server = FakeServer();
      final local = InMemoryLocalStore();
      vm = CatatanViewModel(
        CatatanRepository(local),
        SinkronService(server.api, local),
      );
      await vm.tambahCatatan(c(null, 'State', 5, 'Pemrograman Aplikasi Bergerak'));
      await vm.tambahCatatan(c(null, 'Normalisasi', 7, 'Basis Data'));
      await vm.tambahCatatan(c(null, 'Git', 5, 'Pemrograman Aplikasi Bergerak'));
    });

    test('filter mata kuliah menyaring tampilan, bukan data', () {
      vm.ubahFilterMataKuliah(5);
      expect(vm.catatanTampil.map((e) => e.judul).toSet(), {'State', 'Git'});
      expect(vm.catatan.length, 3);
      expect(vm.sedangMenyaring, isTrue);
    });

    test('filter digabung dengan pencarian', () {
      vm.ubahFilterMataKuliah(5);
      vm.ubahKueri('git');
      expect(vm.catatanTampil.single.judul, 'Git');
      vm.ubahFilterMataKuliah(7);
      expect(vm.catatanTampil, isEmpty);
    });

    test('jumlah chip tidak berubah oleh pencarian', () {
      vm.ubahKueri('git');
      final pab = vm.daftarMataKuliah.firstWhere((e) => e.id == 5);
      expect(pab.jumlah, 2);
    });

    test('kelompokTampil mengikuti filter dan urutan', () {
      vm.ubahUrutan(UrutanCatatan.judulAZ);
      final k = vm.kelompokTampil;
      expect(k.map((e) => e.mataKuliah.nama),
          ['Basis Data', 'Pemrograman Aplikasi Bergerak']);
      expect(k[1].catatan.map((e) => e.judul), ['Git', 'State']);

      vm.ubahFilterMataKuliah(7);
      expect(vm.kelompokTampil.single.mataKuliah.id, 7);
    });

    test('filter dilepas otomatis jika mata kuliahnya tidak punya catatan lagi',
        () async {
      vm.ubahFilterMataKuliah(7);
      final id = vm.catatan.firstWhere((e) => e.mataKuliahId == 7).id!;
      await vm.hapusCatatan(id);
      expect(vm.filterMataKuliahId, isNull);
      expect(vm.catatanTampil.length, 2);
    });

    test('resetPenyaring mengosongkan pencarian dan filter', () {
      vm.ubahFilterMataKuliah(5);
      vm.ubahKueri('git');
      vm.resetPenyaring();
      expect(vm.sedangMenyaring, isFalse);
      expect(vm.kueri, '');
      expect(vm.filterMataKuliahId, isNull);
    });

    test('ubahKelompokkan hanya memberi tahu saat nilai berubah', () {
      var n = 0;
      vm.addListener(() => n++);
      vm.ubahKelompokkan(true);
      vm.ubahKelompokkan(true);
      expect(vm.kelompokkan, isTrue);
      expect(n, 1);
    });
  });
}
