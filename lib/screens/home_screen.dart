import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../viewmodels/catatan_store.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/lifecycle_badge.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/um_widgets.dart';

/// Tab 1: Beranda StudyLog. Fokus utama: catatan kuliah.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.watch<ProfileViewModel>().student;
    final jumlah = context.watch<CatatanStore>().jumlah;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: umAppBar('StudyLog'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeroCard(
            nama: student.nama,
            prodi: student.programStudi,
            semester: student.semester,
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        size: 32, color: UmColors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Catatan Perkuliahan',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: UmColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(jumlah == 0
                    ? 'Belum ada catatan. Mulai dengan membuat catatan pertama.'
                    : '$jumlah catatan (disimpan sementara di memori).'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.daftar),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Lihat Catatan'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.form),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Buat Catatan'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const LifecycleBadge(),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.nama,
    required this.prodi,
    required this.semester,
  });

  final String nama;
  final String prodi;
  final int semester;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: UmColors.navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: UmColors.yellow,
              shape: BoxShape.circle,
            ),
            child: const ProfileAvatar(radius: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Selamat datang,',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 2),
                Text(
                  nama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(prodi, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: UmColors.yellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Semester $semester',
                    style: const TextStyle(
                      color: UmColors.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
