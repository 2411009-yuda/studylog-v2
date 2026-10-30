import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/catatan_repository.dart';
import '../data/local_store.dart';
import '../data/sinkron_service.dart';
import '../data/sqlite_local_store.dart';
import '../data/mata_kuliah_repository.dart';
import '../services/ekspor_service.dart';
import '../viewmodels/catatan_view_model.dart';
import '../viewmodels/mata_kuliah_view_model.dart';
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
    this.sinkronInterval = const Duration(seconds: 20),
  });

  /// Opsional, dipakai pada pengujian untuk menyuntikkan dependensi.
  final ProfileViewModel? viewModel;
  final ApiClient? apiClient;
  final DateTime Function()? clock;
  final EksporService? eksporService;

  /// Penyimpanan lokal. Bawaan: SQLite di perangkat.
  final LocalStore? localStore;

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
