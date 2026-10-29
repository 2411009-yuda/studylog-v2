import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/catatan_store.dart';
import '../viewmodels/profile_viewmodel.dart';
import 'app_router.dart';
import 'routes.dart';
import 'theme.dart';

/// Aplikasi StudyLog. Fitur Profil Mahasiswa menjadi tab pada bottom nav.
class StudyLogApp extends StatelessWidget {
  const StudyLogApp({super.key, this.viewModel, this.catatanStore});

  /// Opsional, dipakai pada pengujian untuk menyuntikkan state.
  final ProfileViewModel? viewModel;
  final CatatanStore? catatanStore;

  @override
  Widget build(BuildContext context) {
    // State dibuat satu kali di atas MaterialApp, sehingga semua layar
    // berbagi state yang sama dan tidak hilang saat pindah layar / rotasi.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProfileViewModel>(
          create: (_) => viewModel ?? ProfileViewModel(),
        ),
        ChangeNotifierProvider<CatatanStore>(
          create: (_) => catatanStore ?? CatatanStore(),
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
