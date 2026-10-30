import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../models/course.dart';
import '../viewmodels/mata_kuliah_view_model.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/um_widgets.dart';

/// Tab 3: daftar mata kuliah semester berjalan (data dari database).
class CourseListScreen extends StatelessWidget {
  const CourseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semester = context.watch<ProfileViewModel>().student.semester;
    final vm = context.watch<MataKuliahViewModel>();

    Widget body;
    if (vm.isLoading && vm.courses.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (vm.error != null && vm.courses.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.black45),
              const SizedBox(height: 12),
              Text(vm.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                style:
                    FilledButton.styleFrom(minimumSize: const Size(160, 44)),
                onPressed: vm.muat,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: vm.muat,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
          children: [
            Text(
              'Mata Kuliah Semester $semester',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: UmColors.navy),
            ),
            const SizedBox(height: 2),
            Text('${vm.courses.length} mata kuliah · ${vm.totalSks} SKS'),
            if (vm.dariCache)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Offline · menampilkan data tersimpan di perangkat',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: UmColors.blue),
                ),
              ),
            const SizedBox(height: 8),
            for (final course in vm.courses) _CourseTile(course: course),
          ],
        ),
      );
    }

    return Scaffold(appBar: umAppBar('Mata Kuliah'), body: body);
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
          // Data dikirim seperlunya: cukup kode mata kuliah.
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
