import 'package:flutter/material.dart';

import '../screens/catatan_form_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/course_detail_screen.dart';
import '../screens/course_list_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/um_widgets.dart';
import 'routes.dart';

/// Pemetaan route -> layar (setara NavHost pada Compose).
Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.home:
      return _page(settings, const HomeScreen());
    case AppRoutes.studylogForm:
      return _page(settings, const CatatanFormScreen());
    case AppRoutes.profile:
      return _page(settings, const ProfileScreen());
    case AppRoutes.contact:
      return _page(settings, const ContactScreen());
    case AppRoutes.courses:
      return _page(settings, const CourseListScreen());
    case AppRoutes.courseDetail:
      final id = settings.arguments;
      if (id is String) {
        return _page(settings, CourseDetailScreen(courseId: id));
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
