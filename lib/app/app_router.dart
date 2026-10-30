import 'package:flutter/material.dart';

import '../screens/catatan_form_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/course_detail_screen.dart';
import '../screens/daftar_catatan_screen.dart';
import '../screens/detail_catatan_screen.dart';
import '../screens/main_shell.dart';
import '../widgets/um_widgets.dart';
import 'routes.dart';

/// Pemetaan route -> layar (setara NavHost pada Compose).
Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.home:
      return _page(settings, const MainShell());
    case AppRoutes.daftar:
      return _page(settings, const DaftarCatatanScreen());
    case AppRoutes.form:
      final args = settings.arguments;
      return _page(
        settings,
        CatatanFormScreen(args: args is CatatanFormArgs ? args : null),
      );
    case AppRoutes.detail:
      final id = settings.arguments;
      if (id is int) {
        return _page(settings, DetailCatatanScreen(id: id));
      }
      return _page(settings, const _NotFoundScreen());
    case AppRoutes.contact:
      return _page(settings, const ContactScreen());
    case AppRoutes.courseDetail:
      final kode = settings.arguments;
      if (kode is String) {
        return _page(settings, CourseDetailScreen(courseId: kode));
      }
      return _page(settings, const _NotFoundScreen());
  }
  return _page(settings, const _NotFoundScreen());
}

MaterialPageRoute<dynamic> _page(RouteSettings settings, Widget child) {
  return MaterialPageRoute<dynamic>(
    settings: settings,
    builder: (_) => child,
  );
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: umAppBar('Tidak ditemukan'),
      body: const Center(child: Text('Halaman tidak tersedia')),
    );
  }
}
