import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/data/catatan_repository.dart';
import 'package:profil_mahasiswa/data/sinkron_service.dart';
import 'package:profil_mahasiswa/models/catatan.dart';
import 'package:profil_mahasiswa/utils/cari_catatan.dart';
import 'package:profil_mahasiswa/utils/urutan_catatan.dart';
import 'package:profil_mahasiswa/viewmodels/catatan_view_model.dart';

import 'fake_server.dart';
import 'in_memory_local_store.dart';

Catatan c(int? id, String judul,
        {String topik = 'Umum',
        String isi = 'isi',
        String mk = 'Pemrograman Aplikasi Bergerak'}) =>
    Catatan(
      id: id,
      mataKuliahId: 5,
      mataKuliahKode: '111000',
      mataKuliahNama: mk,
      topik: topik,
      judul: judul,
      isi: isi,
      tanggal: DateTime(2026, 10, 30, 10).add(Duration(days: id ?? 0)),
    );

void main() {
  final state = c(1, 'Dasar setState', topik: 'State', isi: 'memicu build');
  final git = c(2, 'Git commit', topik: 'Git', isi: 'riwayat perubahan');
  final basis = c(3, 'Normalisasi', topik: 'SQL', isi: 'bentuk normal',
      mk: 'Basis Data');
  final semua = [state, git, basis];

  group('cariCatatan', () {
    test('kueri kosong atau spasi mengembalikan semua', () {
      expect(cariCatatan(semua, ''), semua);
      expect(cariCatatan(semua, '   '), semua);
    });

    test('tidak membedakan huruf besar/kecil', () {
      expect(cariCatatan(semua, 'GIT'), [git]);
    });

    test('mencari di judul, topik, isi, dan mata kuliah', () {
      expect(cariCatatan(semua, 'normalisasi'), [basis]); // judul
      expect(cariCatatan(semua, 'sql'), [basis]); // topik
      expect(cariCatatan(semua, 'riwayat'), [git]); // isi
      expect(cariCatatan(semua, 'basis data'), [basis]); // mata kuliah
      expect(cariCatatan(semua, '111000'), semua); // kode mata kuliah
    });

    test('semua kata harus cocok, boleh di field berbeda', () {
      expect(cariCatatan(semua, 'state pemrograman'), [state]);
      expect(cariCatatan(semua, 'git sql'), isEmpty);
    });

    test('urutan masukan dipertahankan', () {
      expect(cariCatatan(semua, 'pemrograman'), [state, git]);
    });

    test('tidak ada yang cocok -> kosong', () {
      expect(cariCatatan(semua, 'tidak-ada'), isEmpty);
    });
  });

  group('CatatanViewModel pencarian', () {
    late CatatanViewModel vm;

    setUp(() async {
      final server = FakeServer();
      final local = InMemoryLocalStore();
      vm = CatatanViewModel(
        CatatanRepository(local),
        SinkronService(server.api, local),
      );
      await vm.tambahCatatan(c(null, 'Dasar setState', topik: 'State', isi: 'memicu build'));
      await vm.tambahCatatan(c(null, 'Git commit', topik: 'Git', isi: 'riwayat perubahan'));
    });

    test('menyaring tanpa mengubah daftar lengkap', () {
      vm.ubahKueri('git');
      expect(vm.sedangMencari, isTrue);
      expect(vm.hasilCari.single.judul, 'Git commit');
      expect(vm.catatan.length, 2);
    });

    test('hasil mengikuti urutan yang dipilih', () {
      vm.ubahKueri('pemrograman');
      vm.ubahUrutan(UrutanCatatan.judulAZ);
      expect(vm.hasilCari.map((e) => e.judul), ['Dasar setState', 'Git commit']);
    });

    test('mengosongkan kueri menampilkan semua lagi', () {
      vm.ubahKueri('git');
      vm.ubahKueri('');
      expect(vm.sedangMencari, isFalse);
      expect(vm.hasilCari.length, 2);
    });

    test('notifyListeners hanya saat kueri berubah', () {
      var n = 0;
      vm.addListener(() => n++);
      vm.ubahKueri('git');
      vm.ubahKueri('git');
      expect(n, 1);
    });
  });
}
