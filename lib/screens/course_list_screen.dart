import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../models/course.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/um_widgets.dart';

/// Daftar mata kuliah semester berjalan (dipindah dari Beranda lama).
class CourseListScreen extends StatelessWidget {
  const CourseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();

    return Scaffold(
      appBar: umAppBar('Mata Kuliah'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Mata Kuliah Semester ${vm.student.semester}',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: UmColors.navy),
          ),
          const SizedBox(height: 2),
          Text('${vm.courses.length} mata kuliah · ${vm.totalSks} SKS'),
          const SizedBox(height: 8),
          for (final course in vm.courses) _CourseTile(course: course),
        ],
      ),
    );
  }
}

class _CourseTile extends StatelessWidget {
  const _CourseTile({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SectionCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: const CircleAvatar(
            backgroundColor: UmColors.blue,
            child: Icon(Icons.menu_book_outlined, color: Colors.white),
          ),
          title: Text(course.nama),
          subtitle: Text('${course.kode} · ${course.sks} SKS'),
          trailing: const Icon(Icons.chevron_right),
          // Data dikirim seperlunya: cukup id mata kuliah.
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.courseDetail,
            arguments: course.kode,
          ),
        ),
      ),
    );
  }
}
