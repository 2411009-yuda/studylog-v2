import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/lifecycle_badge.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/um_widgets.dart';

/// Layar 1: Beranda StudyLog. Fokus utama: catatan kuliah.
/// Fitur profil mahasiswa tersedia sebagai menu lain di bagian bawah.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.watch<ProfileViewModel>().student;
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
                const Text(
                  'Catat materi kuliah dengan mata kuliah, topik, judul, '
                  'dan isi. Praktikum 1: form interaktif dengan validasi.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.studylogForm),
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Buat Catatan'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Menu Lainnya',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: UmColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MenuButton(
                  icon: Icons.person_outline,
                  label: 'Profil',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MenuButton(
                  icon: Icons.contact_mail_outlined,
                  label: 'Kontak',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.contact),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MenuButton(
            icon: Icons.school_outlined,
            label: 'Mata Kuliah',
            onTap: () => Navigator.pushNamed(context, AppRoutes.courses),
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

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
