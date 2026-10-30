import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../viewmodels/mata_kuliah_view_model.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/um_widgets.dart';

/// Layar 3: Detail Mata Kuliah. Menerima [courseId] dari route.
class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    final semester = context.watch<ProfileViewModel>().student.semester;
    final mkVm = context.watch<MataKuliahViewModel>();
    final course = mkVm.courseByKode(courseId);
    final textTheme = Theme.of(context).textTheme;

    if (course == null) {
      return Scaffold(
        appBar: umAppBar('Detail Mata Kuliah'),
        body: Center(
          child: mkVm.isLoading
              ? const CircularProgressIndicator()
              : const Text('Mata kuliah tidak ditemukan'),
        ),
      );
    }
    final jadwal = mkVm.jadwalUntuk(course.id);

    return Scaffold(
      appBar: umAppBar('Detail Mata Kuliah'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: UmColors.navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.nama,
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(label: 'Kode ${course.kode}'),
                    _Pill(label: '${course.sks} SKS'),
                    _Pill(label: 'Semester $semester'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dosen Pengampu',
                    style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: UmColors.navy)),
                const SizedBox(height: 8),
                Text(course.dosen, style: textTheme.bodyLarge),
                if (jadwal.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Jadwal',
                      style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold, color: UmColors.navy)),
                  const SizedBox(height: 8),
                  for (final j in jadwal)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.schedule,
                              size: 20, color: UmColors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                '${j.label} · ${j.kelas} · ${j.ruang}'),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deskripsi',
                    style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: UmColors.navy)),
                const SizedBox(height: 8),
                Text(course.deskripsi, style: textTheme.bodyLarge),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prasyarat',
                    style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: UmColors.navy)),
                const SizedBox(height: 8),
                if (course.prasyarat.isEmpty)
                  const Text('Tidak ada prasyarat'),
                for (final mk in course.prasyarat)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.link,
                            size: 20, color: UmColors.green),
                        const SizedBox(width: 8),
                        Expanded(child: Text(mk)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            // Tombol kembali: menghapus layar ini dari back stack.
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Kembali'),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: UmColors.yellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: UmColors.navy,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
