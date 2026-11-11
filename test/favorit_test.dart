import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/data/catatan_repository.dart';
import 'package:profil_mahasiswa/data/sinkron_service.dart';
import 'package:profil_mahasiswa/models/catatan.dart';
import 'package:profil_mahasiswa/viewmodels/catatan_view_model.dart';

import 'fake_server.dart';
import 'in_memory_local_store.dart';

Catatan baru(String judul, {int mk = 5, String namaMk = 'Pemrograman'}) =>
    Catatan(
      mataKuliahId: mk,
      mataKuliahKode: 'K$mk',
      mataKuliahNama: namaMk,
      topik: 'Topik',
      judul: judul,
      isi: 'Isi $judul',
      tanggal: DateTime(2026, 10, 30, 19, 5),
    );

void main() {
  late FakeServer server;
  late InMemoryLocalStore local;

  /// Menyimulasikan membuka aplikasi: ViewModel baru, penyimpanan lokal sama.
  CatatanViewModel bukaAplikasi() => CatatanViewModel(
        CatatanRepository(local),
        SinkronService(server.api, local),
      );

  setUp(() {
    server = FakeServer();
    local = InMemoryLocalStore();
  });

  Catatan cari(CatatanViewModel vm, String judul) =>
      vm.catatan.firstWhere((c) => c.judul == judul);

  test('catatan baru tidak favorit', () async {
    final vm = bukaAplikasi();
    await vm.tambahCatatan(baru('A'));
    expect(vm.catatan.single.favorit, isFalse);
    expect(vm.jumlahFavorit, 0);
  });

  test('tandai dan lepas favorit', () async {
    final vm = bukaAplikasi();
    await vm.tambahCatatan(baru('A'));
    final id = cari(vm, 'A').id!;

    await vm.setFavorit(id, true);
    expect(cari(vm, 'A').favorit, isTrue);
    expect(vm.jumlahFavorit, 1);

    await vm.setFavorit(id, false);
    expect(cari(vm, 'A').favorit, isFalse);
    expect(vm.jumlahFavorit, 0);
  });

  test('status favorit bertahan setelah aplikasi ditutup dan dibuka lagi',
      () async {
    final pertama = bukaAplikasi();
    await pertama.tambahCatatan(baru('A'));
    await pertama.tambahCatatan(baru('B'));
    await pertama.setFavorit(cari(pertama, 'A').id!, true);

    // "Tutup" aplikasi, lalu buka lagi dengan data lokal yang sama.
    final kedua = bukaAplikasi();
    await kedua.muatCatatan();

    expect(cari(kedua, 'A').favorit, isTrue);
    expect(cari(kedua, 'B').favorit, isFalse);
  });

  test('favorit tidak masuk antrian sinkron dan tidak menandai "menunggu"',
      () async {
    final vm = bukaAplikasi();
    await vm.tambahCatatan(baru('A'));
    await vm.sinkronkan();
    expect(vm.tertunda, 0);

    await vm.setFavorit(cari(vm, 'A').id!, true);

    expect(vm.tertunda, 0);
    expect(cari(vm, 'A').menunggu, isFalse);
  });

  test('favorit bertahan setelah catatan diubah', () async {
    final vm = bukaAplikasi();
    await vm.tambahCatatan(baru('A'));
    await vm.setFavorit(cari(vm, 'A').id!, true);

    await vm.ubahCatatan(cari(vm, 'A').copyWith(judul: 'A diubah'));

    expect(cari(vm, 'A diubah').favorit, isTrue);
  });

  test('favorit bertahan setelah sinkronisasi menarik data server', () async {
    final vm = bukaAplikasi();
    await vm.tambahCatatan(baru('A'));
    await vm.sinkronkan();
    await vm.setFavorit(cari(vm, 'A').id!, true);

    await vm.sinkronkan();
    expect(cari(vm, 'A').favorit, isTrue);

    final baruDibuka = bukaAplikasi();
    await baruDibuka.mulai(); // muat lokal + sinkron
    expect(cari(baruDibuka, 'A').favorit, isTrue);
  });

  test('filter hanya favorit, digabung dengan filter mata kuliah', () async {
    final vm = bukaAplikasi();
    await vm.tambahCatatan(baru('A'));
    await vm.tambahCatatan(baru('B'));
    await vm.tambahCatatan(baru('C', mk: 7, namaMk: 'Basis Data'));
    await vm.setFavorit(cari(vm, 'A').id!, true);
    await vm.setFavorit(cari(vm, 'C').id!, true);

    vm.ubahHanyaFavorit(true);
    expect(vm.catatanTampil.map((c) => c.judul).toSet(), {'A', 'C'});
    expect(vm.sedangMenyaring, isTrue);

    vm.ubahFilterMataKuliah(7);
    expect(vm.catatanTampil.single.judul, 'C');

    vm.resetPenyaring();
    expect(vm.hanyaFavorit, isFalse);
    expect(vm.catatanTampil.length, 3);
  });
}
