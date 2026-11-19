import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/catatan_repository.dart';
import '../data/local_store.dart';
import '../data/sinkron_service.dart';
import '../data/sqlite_local_store.dart';
import '../config/api_config.dart';
import '../data/mata_kuliah_repository.dart';
import '../data/penilaian_repository.dart';
import '../data/realtime_service.dart';
import '../services/notifikasi_service.dart';
import '../services/ekspor_service.dart';
import '../viewmodels/catatan_view_model.dart';
import '../viewmodels/mata_kuliah_view_model.dart';
import '../viewmodels/pengingat_view_model.dart';
import '../viewmodels/penilaian_view_model.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/sinkron_pemicu.dart';
import 'app_router.dart';
import 'routes.dart';
import 'theme.dart';

/// Aplikasi StudyLog. Fitur Profil Mahasiswa menjadi tab pada bottom nav.
class StudyLogApp extends StatelessWidget {
  const StudyLogApp({
    super.key,
    this.viewModel,
    this.apiClient,
    this.clock,
    this.eksporService,
    this.localStore,
    this.realtimeService,
    this.notifikasiService,
    this.awalSemester,
    this.sinkronInterval = const Duration(seconds: 20),
  });

  /// Opsional, dipakai pada pengujian untuk menyuntikkan dependensi.
  final ProfileViewModel? viewModel;
  final ApiClient? apiClient;
  final DateTime Function()? clock;
  final EksporService? eksporService;

  /// Penyimpanan lokal. Bawaan: SQLite di perangkat.
  final LocalStore? localStore;

  /// Layanan real-time. Bawaan: WebSocket ke server API.
  final RealtimeService? realtimeService;

  /// Notifikasi sistem untuk pengingat. Bawaan: notifikasi lokal Android.
  final NotifikasiService? notifikasiService;

  /// Tanggal mulai kuliah semester ini (bawaan: lihat pengingat_config.dart).
  final DateTime? awalSemester;

  /// Jeda sinkronisasi berkala (null = nonaktif, dipakai pada pengujian).
  final Duration? sinkronInterval;

  @override
  Widget build(BuildContext context) {
    final api = apiClient ?? ApiClient();
    final local = localStore ?? SqliteLocalStore();

    // State dibuat satu kali di atas MaterialApp, sehingga semua layar
    // berbagi state yang sama dan tidak hilang saat pindah layar / rotasi.
    return MultiProvider(
      providers: [
        Provider<EksporService>(
          create: (_) => eksporService ?? const EksporServiceBawaan(),
        ),
        ChangeNotifierProvider<RealtimeService>(
          create: (_) =>
              realtimeService ?? RealtimeService(uri: ApiConfig.wsUri),
        ),
        ChangeNotifierProvider<ProfileViewModel>(
          create: (_) => viewModel ?? ProfileViewModel(),
        ),
        ChangeNotifierProvider<CatatanViewModel>(
          create: (_) => CatatanViewModel(
            CatatanRepository(local),
            SinkronService(api, local),
          )..mulai(),
        ),
        ChangeNotifierProvider<MataKuliahViewModel>(
          create: (_) => MataKuliahViewModel(
            MataKuliahRepository(api, local),
            clock: clock,
          )..muat(),
        ),
        ChangeNotifierProvider<PenilaianViewModel>(
          create: (_) => PenilaianViewModel(
            PenilaianRepository(api, local, clock: clock),
          )..mulai(),
        ),
        ChangeNotifierProvider<PengingatViewModel>(
          lazy: false,
          create: (ctx) => PengingatViewModel(
            mataKuliah: ctx.read<MataKuliahViewModel>(),
            penilaian: ctx.read<PenilaianViewModel>(),
            catatan: ctx.read<CatatanViewModel>(),
            notifikasi: notifikasiService ?? NotifikasiLokal(),
            awalSemester: awalSemester,
            clock: clock,
          )..mulai(),
        ),
      ],
      child: SinkronPemicu(
        interval: sinkronInterval,
        child: MaterialApp(
          title: 'StudyLog',
          debugShowCheckedModeBanner: false,
          theme: buildUmTheme(),
          initialRoute: AppRoutes.home,
          onGenerateRoute: onGenerateRoute,
        ),
      ),
    );
  }
}
