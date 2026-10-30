import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/config/api_config.dart';
import 'package:profil_mahasiswa/data/realtime_service.dart';

import 'fake_realtime.dart';

/// Pengujian dengan timer sungguhan berdurasi pendek (puluhan milidetik).
Future<void> tunggu(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

const eventCatatan = {'tipe': 'catatan', 'aksi': 'dibuat', 'id': 1};

RealtimeService buat(
  FakeRealtime fake, {
  Duration debounce = Duration.zero,
  Uri? uri,
  bool tanpaUri = false,
}) =>
    RealtimeService(
      uri: tanpaUri ? null : (uri ?? Uri.parse('ws://x/ws')),
      penyambung: fake.penyambung,
      debounce: debounce,
      jedaAwal: const Duration(milliseconds: 10),
      jedaMaks: const Duration(milliseconds: 40),
    );

void main() {
  group('jeda sambung ulang', () {
    test('naik dua kali lipat dan dibatasi jedaMaks', () {
      const awal = Duration(seconds: 1);
      const maks = Duration(seconds: 30);
      expect(RealtimeService.jeda(0, awal, maks), const Duration(seconds: 1));
      expect(RealtimeService.jeda(1, awal, maks), const Duration(seconds: 2));
      expect(RealtimeService.jeda(2, awal, maks), const Duration(seconds: 4));
      expect(RealtimeService.jeda(4, awal, maks), const Duration(seconds: 16));
      expect(RealtimeService.jeda(5, awal, maks), maks);
      expect(RealtimeService.jeda(1000, awal, maks), maks);
    });
  });

  group('wsUriDari', () {
    test('http -> ws dan https -> wss, path /ws', () {
      expect(wsUriDari('http://10.0.2.2:3000').toString(), 'ws://10.0.2.2:3000/ws');
      expect(wsUriDari('http://192.168.1.10:3000').toString(),
          'ws://192.168.1.10:3000/ws');
      expect(wsUriDari('https://api.contoh.id').toString(), 'wss://api.contoh.id/ws');
    });
  });

  group('RealtimeService', () {
    late FakeRealtime fake;
    late RealtimeService svc;
    late int perubahan;
    late int tersambung;

    RealtimeService pasang(RealtimeService s) {
      perubahan = 0;
      tersambung = 0;
      s.onPerubahan = () => perubahan++;
      s.onTersambung = () => tersambung++;
      return s;
    }

    setUp(() => fake = FakeRealtime());
    tearDown(() => svc.dispose());

    test('mulai: menyambung lalu tersambung dan memanggil onTersambung',
        () async {
      svc = pasang(buat(fake));
      final status = <StatusRealtime>[];
      svc.addListener(() => status.add(svc.status));

      svc.mulai();
      await tunggu(30);

      expect(status, [StatusRealtime.menyambung, StatusRealtime.tersambung]);
      expect(svc.tersambung, isTrue);
      expect(tersambung, 1);
      expect(perubahan, 0);
    });

    test('kabar catatan memicu onPerubahan; kabar lain diabaikan', () async {
      svc = pasang(buat(fake))..mulai();
      await tunggu(30);

      fake.kirim({'tipe': 'halo'});
      fake.kirimMentah('bukan json {');
      fake.kirimMentah(42);
      fake.kirim({'tipe': 'lain'});
      await tunggu(20);
      expect(perubahan, 0);

      fake.kirim(eventCatatan);
      await tunggu(20);
      expect(perubahan, 1);
    });

    test('debounce: kabar beruntun digabung menjadi satu penarikan', () async {
      svc = pasang(buat(fake, debounce: const Duration(milliseconds: 40)))
        ..mulai();
      await tunggu(30);

      for (var i = 0; i < 5; i++) {
        fake.kirim(eventCatatan);
      }
      await tunggu(20);
      expect(perubahan, 0); // masih menunggu jeda
      await tunggu(80);
      expect(perubahan, 1);
    });

    test('sambungan putus: otomatis menyambung ulang dan menarik data lagi',
        () async {
      svc = pasang(buat(fake))..mulai();
      await tunggu(30);
      expect(tersambung, 1);

      fake.putus();
      await tunggu(10);
      expect(svc.status, isNot(StatusRealtime.tersambung));

      await tunggu(80);
      expect(fake.sambungan, hasLength(2));
      expect(svc.tersambung, isTrue);
      expect(tersambung, 2); // tarik ulang demi mengejar kabar yang terlewat
    });

    test('gagal menyambung: dicoba lagi bertahap, lalu pulih', () async {
      fake.gagalSambung = true;
      svc = pasang(buat(fake))..mulai();
      await tunggu(150);

      expect(fake.percobaan, greaterThanOrEqualTo(3));
      expect(svc.status, isNot(StatusRealtime.tersambung));
      expect(tersambung, 0);

      fake.gagalSambung = false;
      await tunggu(120); // jedaMaks 40 ms
      expect(svc.tersambung, isTrue);
      expect(tersambung, 1);
    });

    test('berhenti: koneksi ditutup dan tidak menyambung ulang', () async {
      svc = pasang(buat(fake))..mulai();
      await tunggu(30);

      await svc.berhenti();
      expect(svc.status, StatusRealtime.terputus);
      expect(svc.aktif, isFalse);
      expect(fake.sambungan.single.tertutup, isTrue);

      await tunggu(100);
      expect(fake.percobaan, 1);
    });

    test('berhenti lalu mulai lagi menyambung kembali', () async {
      svc = pasang(buat(fake))..mulai();
      await tunggu(30);
      await svc.berhenti();

      svc.mulai();
      await tunggu(30);
      expect(fake.percobaan, 2);
      expect(svc.tersambung, isTrue);
    });

    test('mulai dua kali tidak membuat dua koneksi', () async {
      svc = pasang(buat(fake))
        ..mulai()
        ..mulai();
      await tunggu(40);
      expect(fake.percobaan, 1);
    });

    test('tanpa alamat (uri null): tidak melakukan apa pun', () async {
      svc = pasang(buat(fake, tanpaUri: true))..mulai();
      await tunggu(40);

      expect(fake.percobaan, 0);
      expect(svc.aktif, isFalse);
      expect(svc.status, StatusRealtime.terputus);
    });

    test('kabar yang datang setelah berhenti tidak memicu apa pun', () async {
      svc = pasang(buat(fake))..mulai();
      await tunggu(30);
      final lama = fake.sambungan.single;
      await svc.berhenti();

      if (!lama.controller.isClosed) lama.controller.add('{"tipe":"catatan"}');
      await tunggu(20);
      expect(perubahan, 0);
    });

    test('dispose di tengah menyambung tidak menimbulkan error', () async {
      svc = buat(fake); // dibuang oleh tearDown
      final lain = pasang(buat(FakeRealtime()))..mulai();
      lain.dispose(); // sambungan masih berjalan saat dibuang
      await tunggu(40);
      expect(perubahan, 0);
      expect(tersambung, 0);
    });
  });
}
