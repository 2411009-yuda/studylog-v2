import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../config/pengingat_config.dart';

/// Pengiriman notifikasi sistem. Dibuat sebagai antarmuka agar pengujian
/// tidak menyentuh plugin sungguhan.
abstract class NotifikasiService {
  /// Menjadwalkan notifikasi yang berulang setiap hari pada jam:menit
  /// (menggantikan jadwal sebelumnya).
  Future<void> jadwalkanHarian({
    required String judul,
    required String isi,
    required int jam,
    required int menit,
  });

  /// Membatalkan notifikasi harian (tidak ada lagi yang terlewat).
  Future<void> batalkanHarian();

  /// Menampilkan notifikasi sekarang juga (untuk uji coba). Mengembalikan
  /// false jika notifikasi tidak dapat ditampilkan (mis. izin ditolak).
  Future<bool> tampilkanSekarang({required String judul, required String isi});
}

/// Tidak melakukan apa pun. Dipakai pada pengujian.
class NotifikasiTidakAktif implements NotifikasiService {
  const NotifikasiTidakAktif();

  @override
  Future<void> jadwalkanHarian({
    required String judul,
    required String isi,
    required int jam,
    required int menit,
  }) async {}

  @override
  Future<void> batalkanHarian() async {}

  @override
  Future<bool> tampilkanSekarang({
    required String judul,
    required String isi,
  }) async =>
      true;
}

/// Notifikasi lokal Android lewat flutter_local_notifications.
/// Semua kegagalan ditelan: pengingat tidak boleh membuat aplikasi rusak.
class NotifikasiLokal implements NotifikasiService {
  NotifikasiLokal({this.zonaWaktu = zonaWaktuPengingat});

  final String zonaWaktu;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _idHarian = 1001;
  static const _idUji = 1002;
  static const _kanal = AndroidNotificationDetails(
    'pengingat_akademik',
    'Pengingat akademik',
    channelDescription:
        'Pengingat penilaian dosen dan catatan kelas yang terlewat',
  );

  Future<bool>? _siap;
  bool _izinSudahDiminta = false;

  Future<bool> _init() => _siap ??= _mulai();

  Future<bool> _mulai() async {
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation(zonaWaktu));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      return true;
    } catch (e) {
      debugPrint('[Notifikasi] gagal inisialisasi: $e');
      return false;
    }
  }

  /// Izin notifikasi (Android 13+) baru diminta saat pertama kali dibutuhkan
  /// (ada yang perlu diingatkan / uji coba), bukan saat aplikasi dibuka.
  /// Mengembalikan true jika notifikasi diizinkan.
  Future<bool> _izinAktif() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    if (!_izinSudahDiminta) {
      _izinSudahDiminta = true;
      await android.requestNotificationsPermission();
    }
    return await android.areNotificationsEnabled() ?? true;
  }

  @override
  Future<void> jadwalkanHarian({
    required String judul,
    required String isi,
    required int jam,
    required int menit,
  }) async {
    try {
      if (!await _init()) return;
      await _izinAktif();
      final sekarang = tz.TZDateTime.now(tz.local);
      var waktu = tz.TZDateTime(
          tz.local, sekarang.year, sekarang.month, sekarang.day, jam, menit);
      if (!waktu.isAfter(sekarang)) {
        waktu = waktu.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id: _idHarian,
        title: judul,
        body: isi,
        scheduledDate: waktu,
        notificationDetails: const NotificationDetails(android: _kanal),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('[Notifikasi] gagal menjadwalkan: $e');
    }
  }

  @override
  Future<void> batalkanHarian() async {
    try {
      if (!await _init()) return;
      await _plugin.cancel(id: _idHarian);
    } catch (e) {
      debugPrint('[Notifikasi] gagal membatalkan: $e');
    }
  }

  @override
  Future<bool> tampilkanSekarang({
    required String judul,
    required String isi,
  }) async {
    try {
      if (!await _init()) return false;
      if (!await _izinAktif()) return false;
      await _plugin.show(
        id: _idUji,
        title: judul,
        body: isi,
        notificationDetails: const NotificationDetails(android: _kanal),
      );
      return true;
    } catch (e) {
      debugPrint('[Notifikasi] gagal menampilkan: $e');
      return false;
    }
  }
}
