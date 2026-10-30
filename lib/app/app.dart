import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/api_client.dart';
import '../data/catatan_repository.dart';
import '../data/mata_kuliah_repository.dart';
import '../viewmodels/catatan_view_model.dart';
import '../viewmodels/mata_kuliah_view_model.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'app_router.dart';
import 'routes.dart';
import 'theme.dart';

/// Aplikasi StudyLog. Fitur Profil Mahasiswa menjadi tab pada bottom nav.
class StudyLogApp extends StatelessWidget {
  const StudyLogApp({super.key, this.viewModel, this.apiClient, this.clock});

  /// Opsional, dipakai pada pengujian untuk menyuntikkan dependensi.
  final ProfileViewModel? viewModel;
  final ApiClient? apiClient;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    final api = apiClient ?? ApiClient();

    // State dibuat satu kali di atas MaterialApp, sehingga semua layar
    // berbagi state yang sama dan tidak hilang saat pindah layar / rotasi.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileViewModel>(
          create: (_) => viewModel ?? ProfileViewModel(),
        ),
        ChangeNotifierProvider<CatatanViewModel>(
          create: (_) =>
              CatatanViewModel(CatatanRepository(api))..muatCatatan(),
        ),
        ChangeNotifierProvider<MataKuliahViewModel>(
          create: (_) => MataKuliahViewModel(
            MataKuliahRepository(api),
            clock: clock,
          )..muat(),
        ),
      ],
      child: MaterialApp(
        title: 'StudyLog',
        debugShowCheckedModeBanner: false,
        theme: buildUmTheme(),
        initialRoute: AppRoutes.home,
        onGenerateRoute: onGenerateRoute,
      ),
    );
  }
}
