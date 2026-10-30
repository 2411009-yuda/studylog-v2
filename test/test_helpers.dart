import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/app/app.dart';
import 'package:profil_mahasiswa/data/local_store.dart';
import 'package:profil_mahasiswa/data/realtime_service.dart';
import 'package:profil_mahasiswa/services/ekspor_service.dart';

import 'fake_realtime.dart';
import 'fake_server.dart';
import 'in_memory_local_store.dart';

/// Jumat 30 Okt 2026 20:40 -> kelas Pemrograman Aplikasi Bergerak berlangsung.
final jumatMalam = DateTime(2026, 10, 30, 20, 40);

/// Sabtu 31 Okt 2026 10:00 -> tidak ada kelas.
final sabtuPagi = DateTime(2026, 10, 31, 10, 0);

/// Layar uji bawaan hanya 800x600, sehingga tombol di bagian bawah layar
/// berada di luar jangkauan tap. Layar yang lebih tinggi memuat semua konten.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Pengganti clipboard dan share sheet (tidak tersedia pada lingkungan tes).
class FakeEksporService implements EksporService {
  final List<String> disalin = [];
  final List<String> dibagikan = [];

  @override
  Future<void> salin(String teks) async => disalin.add(teks);

  @override
  Future<void> bagikan(String teks, {String? subjek}) async =>
      dibagikan.add(teks);
}

/// Membuka aplikasi dengan server tiruan dan jam yang dapat diatur.
Future<void> bukaApp(
  WidgetTester tester,
  FakeServer server, {
  DateTime? sekarang,
  EksporService? ekspor,
  LocalStore? local,
  Duration? interval,
  FakeRealtime? realtime,
}) async {
  useTallScreen(tester);
  final waktu = sekarang ?? jumatMalam;
  // Tanpa FakeRealtime, real-time dinonaktifkan (uri null) agar tes tidak
  // mencoba membuka WebSocket sungguhan.
  realtime?.hubungkan(server);
  final layananRealtime = RealtimeService(
    uri: realtime == null ? null : Uri.parse('ws://fake/ws'),
    penyambung: realtime?.penyambung,
    debounce: Duration.zero,
    jedaAwal: const Duration(milliseconds: 10),
  );
  await tester.pumpWidget(StudyLogApp(
    apiClient: server.api,
    clock: () => waktu,
    eksporService: ekspor ?? FakeEksporService(),
    // Penyimpanan lokal baru untuk tiap pembukaan, kecuali diberikan
    // (menyimulasikan "tutup lalu buka aplikasi" dengan data lokal yang sama).
    localStore: local ?? InMemoryLocalStore(),
    sinkronInterval: interval,
    realtimeService: layananRealtime,
  ));
  await tester.pumpAndSettle();
}

/// Menekan satu tab pada bottom bar (bukan teks lain dengan nama sama).
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
    of: find.byType(BottomAppBar),
    matching: find.text(label),
  ));
  await tester.pumpAndSettle();
}

/// Menekan tombol + di tengah bottom bar.
Future<void> tapPlus(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Catatan baru'));
  await tester.pumpAndSettle();
}

/// Urutan field teks: 0 topik, 1 judul, 2 isi (dropdown bukan TextFormField).
Future<void> isiForm(
  WidgetTester tester, {
  String topik = 'State',
  String judul = 'Dasar setState',
  String isi = 'setState memicu build ulang.',
}) async {
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), topik);
  await tester.enterText(fields.at(1), judul);
  await tester.enterText(fields.at(2), isi);
  await tester.pump();
}
