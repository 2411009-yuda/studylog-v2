import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/profile_viewmodel.dart';
import 'app_router.dart';
import 'routes.dart';
import 'theme.dart';

/// Aplikasi StudyLog. Fitur Profil Mahasiswa tetap ada sebagai menu lain.
class StudyLogApp extends StatelessWidget {
  const StudyLogApp({super.key, this.viewModel});

  /// Opsional, dipakai pada pengujian untuk menyuntikkan ViewModel.
  final ProfileViewModel? viewModel;

  @override
  Widget build(BuildContext context) {
    // ProfileViewModel dibuat satu kali di atas MaterialApp, sehingga semua
    // layar profil berbagi state yang sama. Form catatan (M1) memakai state
    // lokal StatefulWidget sesuai Praktikum 1.
    return ChangeNotifierProvider<ProfileViewModel>(
      create: (_) => viewModel ?? ProfileViewModel(),
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
