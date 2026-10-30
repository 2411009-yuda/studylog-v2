import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/data/catatan_repository.dart';
import 'package:profil_mahasiswa/data/local_store.dart';
import 'package:profil_mahasiswa/data/sinkron_service.dart';
import 'package:profil_mahasiswa/models/catatan.dart';

import 'fake_server.dart';
import 'in_memory_local_store.dart';

Catatan baru({String judul = 'Judul'}) => Catatan(
      mataKuliahId: 5,
      mataKuliahKode: '111000',
      mataKuliahNama: 'Pemrograman Aplikasi Bergerak',
      topik: 'Topik',
      judul: judul,
      isi: 'Isi',
      tanggal: DateTime(2026, 10, 30, 19, 5),
    );

void main() {
  late FakeServer server;
  late InMemoryLocalStore local;
  late CatatanRepository repo;
  late SinkronService service;

  setUp(() {
    server = FakeServer();
    local = InMemoryLocalStore();
    repo = CatatanRepository(local);
    service = SinkronService(server.api, local);
  });

  group('Repository (offline-first)', () {
    test('tambah: tersimpan lokal + masuk antrian, server belum tahu',
        () async {
      final c = await repo.tambah(baru());

      expect(c.id, isNotNull);
      expect(c.clientId, isNotEmpty);
      expect(c.serverId, isNull);
      expect((await repo.semua()).single.menunggu, isTrue);
      final antrian = await repo.antrian();
      expect(antrian.single.op, OpAntrian.upsert);
      expect(antrian.single.clientId, c.clientId);
      expect(server.catatan, isEmpty);
    });

    test('ubah sebelum sinkron: tetap SATU entri antrian dengan versi naik',
        () async {
      final c = await repo.tambah(baru(judul: 'Awal'));
      await repo.ubah(c.copyWith(judul: 'Diubah'));

      final antrian = await repo.antrian();
      expect(antrian, hasLength(1));
      expect(antrian.single.versi, 2);
      expect((await repo.semua()).single.judul, 'Diubah');
    });

    test('hapus: hilang di lokal seketika, antrian berisi hapus', () async {
      final c = await repo.tambah(baru());
      await repo.hapus(c.id!);

      expect(await repo.semua(), isEmpty);
      final antrian = await repo.antrian();
      expect(antrian.single.op, OpAntrian.hapus);
    });

    test('hapus id yang tidak ada tidak melakukan apa pun', () async {
      await repo.hapus(999);
      expect(await repo.antrian(), isEmpty);
    });

    test('ubah tanpa id/clientId melempar ArgumentError', () async {
      await expectLater(() => repo.ubah(baru()), throwsArgumentError);
    });

    test('clientId setiap catatan berbeda', () async {
      final a = await repo.tambah(baru());
      final b = await repo.tambah(baru());
      expect(a.clientId, isNot(b.clientId));
    });
  });

  group('SinkronService: mengirim antrian', () {
    test('kirim: server menerima, antrian kosong, serverId terisi, tanggal asli',
        () async {
      await repo.tambah(baru());

      final hasil = await service.sinkronkan();

      expect(hasil.offline, isFalse);
      expect(hasil.terkirim, 1);
      expect(server.catatan.single['judul'], 'Judul');
      // Tanggal pembuatan di perangkat dipertahankan, bukan waktu sinkron.
      expect(server.catatan.single['tanggal'], '2026-10-30 19:05:00');
      expect(await local.antrian(), isEmpty);
      final lokal = (await local.semuaCatatan()).single;
      expect(lokal.serverId, server.catatan.single['id']);
      expect(lokal.menunggu, isFalse);
    });

    test('ubah sebelum sinkron: server menerima SEKALI dengan isi terbaru',
        () async {
      final c = await repo.tambah(baru(judul: 'Awal'));
      await repo.ubah(c.copyWith(judul: 'Terbaru'));

      await service.sinkronkan();

      expect(server.putKlienCount, 1);
      expect(server.catatan.single['judul'], 'Terbaru');
    });

    test('ubah catatan yang sudah tersinkron: server diperbarui, tanpa duplikat',
        () async {
      final c = await repo.tambah(baru(judul: 'Awal'));
      await service.sinkronkan();
      final tersinkron = (await local.semuaCatatan()).single;

      await repo.ubah(tersinkron.copyWith(judul: 'Revisi'));
      await service.sinkronkan();

      expect(server.catatan, hasLength(1));
      expect(server.catatan.single['judul'], 'Revisi');
      expect(server.catatan.single['clientId'], c.clientId);
    });

    test('hapus catatan yang sudah tersinkron menghapusnya di server',
        () async {
      final c = await repo.tambah(baru());
      await service.sinkronkan();

      await repo.hapus((await local.semuaCatatan()).single.id!);
      await service.sinkronkan();

      expect(server.catatan, isEmpty);
      expect(await local.semuaCatatan(), isEmpty);
      expect(await local.antrian(), isEmpty);
      expect(c.clientId, isNotEmpty);
    });

    test('dibuat lalu dihapus saat offline: server tetap kosong', () async {
      server.down = true;
      final c = await repo.tambah(baru());
      await repo.hapus(c.id!);
      expect((await service.sinkronkan()).offline, isTrue);

      server.down = false;
      await service.sinkronkan();

      expect(server.catatan, isEmpty);
      expect(await local.semuaCatatan(), isEmpty);
      expect(await local.antrian(), isEmpty);
    });

    test('server mati: antrian ditahan, hasil offline, pull dilewati',
        () async {
      await repo.tambah(baru());
      server.down = true;

      final hasil = await service.sinkronkan();

      expect(hasil.offline, isTrue);
      expect(hasil.terkirim, 0);
      expect(await local.antrian(), hasLength(1));
    });

    test('balasan hilang di jalan lalu dikirim ulang: TIDAK duplikat',
        () async {
      await repo.tambah(baru(judul: 'Sekali saja'));

      server.dropResponse = true;
      final gagal = await service.sinkronkan();
      expect(gagal.offline, isTrue);
      expect(server.catatan, hasLength(1)); // server sempat memprosesnya
      expect(await local.antrian(), hasLength(1)); // aplikasi tidak tahu

      server.dropResponse = false;
      final ulang = await service.sinkronkan();

      expect(ulang.offline, isFalse);
      expect(server.catatan, hasLength(1));
      expect(await local.antrian(), isEmpty);
      expect((await local.semuaCatatan()).single.serverId,
          server.catatan.single['id']);
    });

    test('diubah saat pengiriman berjalan: perubahan baru TIDAK hilang',
        () async {
      await repo.tambah(baru(judul: 'Versi 1'));
      var sudah = false;
      server.onPutKlien = () async {
        if (sudah) return;
        sudah = true;
        final c = (await local.semuaCatatan()).single;
        await repo.ubah(c.copyWith(judul: 'Versi 2 (saat kirim)'));
      };

      await service.sinkronkan();

      // Kiriman pertama membawa versi 1; versi 2 masih menunggu di antrian.
      expect(server.catatan.single['judul'], 'Versi 1');
      expect(await local.antrian(), hasLength(1));
      expect((await local.semuaCatatan()).single.judul, 'Versi 2 (saat kirim)');

      await service.sinkronkan();

      expect(server.catatan.single['judul'], 'Versi 2 (saat kirim)');
      expect(await local.antrian(), isEmpty);
    });

    test('ditolak server (4xx): ditandai, tidak memblokir item lain',
        () async {
      // B sudah tersinkron, lalu dihapus; A baru dan akan ditolak.
      await repo.tambah(baru(judul: 'B'));
      await service.sinkronkan();
      await repo.hapus((await local.semuaCatatan()).single.id!);
      await repo.tambah(baru(judul: 'A'));

      server.tolakKlien = 'Mata kuliah tidak ditemukan';
      final hasil = await service.sinkronkan();

      expect(hasil.offline, isFalse);
      expect(hasil.ditolak, 1);
      expect(hasil.terkirim, 1); // penghapusan B tetap terkirim
      expect(hasil.pesan, 'Mata kuliah tidak ditemukan');
      expect(server.catatan, isEmpty);
      final sisa = await local.antrian();
      expect(sisa.single.error, 'Mata kuliah tidak ditemukan');
      expect(sisa.single.percobaan, 1);
      // Catatan A tetap ada di perangkat, tidak hilang karena pull.
      expect((await local.semuaCatatan()).single.judul, 'A');
    });

    test('entri antrian yang catatannya sudah tidak ada dibuang', () async {
      await local.setAntrian('tidak-ada', OpAntrian.upsert);
      final hasil = await service.sinkronkan();
      expect(hasil.offline, isFalse);
      expect(await local.antrian(), isEmpty);
    });
  });

  group('SinkronService: menarik data server', () {
    test('catatan dari perangkat lain muncul, tanpa duplikat saat diulang',
        () async {
      server.seedCatatan(judul: 'Dari HP lain');

      await service.sinkronkan();
      final pertama = (await local.semuaCatatan()).single;
      expect(pertama.judul, 'Dari HP lain');
      expect(pertama.menunggu, isFalse);
      expect(pertama.serverId, isNotNull);

      await service.sinkronkan();
      final kedua = await local.semuaCatatan();
      expect(kedua, hasLength(1));
      expect(kedua.single.id, pertama.id); // id lokal stabil
    });

    test('perubahan di perangkat lain menimpa salinan lokal yang bersih',
        () async {
      await repo.tambah(baru(judul: 'Awal'));
      await service.sinkronkan();

      server.catatan.single['judul'] = 'Diubah di HP lain';
      await service.sinkronkan();

      expect((await local.semuaCatatan()).single.judul, 'Diubah di HP lain');
    });

    test('perubahan lokal yang tertunda TIDAK ditimpa data server', () async {
      final c = await repo.tambah(baru(judul: 'Awal'));
      await service.sinkronkan();
      final tersinkron = (await local.semuaCatatan()).single;
      await repo.ubah(tersinkron.copyWith(judul: 'Perubahan lokal'));

      // Server menolak kiriman, tetapi tetap bisa ditarik: lokal harus menang.
      server.tolakKlien = 'ditolak';
      server.catatan.single['judul'] = 'Versi server';
      await service.sinkronkan();

      expect((await local.semuaCatatan()).single.judul, 'Perubahan lokal');
      expect(c.clientId, isNotEmpty);
    });

    test('dihapus di perangkat lain -> hilang di lokal', () async {
      await repo.tambah(baru());
      await service.sinkronkan();
      expect(await local.semuaCatatan(), hasLength(1));

      server.catatan.clear();
      await service.sinkronkan();

      expect(await local.semuaCatatan(), isEmpty);
    });

    test('catatan baru yang belum terkirim tidak ikut terhapus oleh pull',
        () async {
      await repo.tambah(baru(judul: 'Belum terkirim'));
      server.tolakKlien = 'ditolak'; // tetap tertunda, pull tetap berjalan

      await service.sinkronkan();

      expect((await local.semuaCatatan()).single.judul, 'Belum terkirim');
    });
  });
}
