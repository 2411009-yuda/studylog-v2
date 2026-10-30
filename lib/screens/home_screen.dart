import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../utils/navigasi_catatan.dart';
import '../viewmodels/catatan_view_model.dart';
import '../viewmodels/mata_kuliah_view_model.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/indikator_realtime.dart';
import '../widgets/lifecycle_badge.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/status_sinkron_banner.dart';
import '../widgets/um_widgets.dart';

/// Tab 1: Beranda StudyLog. Fokus utama: catatan kuliah.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.watch<ProfileViewModel>().student;
    final catatanVm = context.watch<CatatanViewModel>();
    final mkVm = context.watch<MataKuliahViewModel>();
    final textTheme = Theme.of(context).textTheme;

    final terdekat = mkVm.jadwalTerdekat();
    final course =
        terdekat == null ? null : mkVm.courseById(terdekat.jadwal.mataKuliahId);

    final String ringkasan;
    if (catatanVm.error != null) {
      ringkasan = catatanVm.error!;
    } else if (catatanVm.isLoading && catatanVm.catatan.isEmpty) {
      ringkasan = 'Memuat catatan...';
    } else if (catatanVm.catatan.isEmpty) {
      ringkasan = 'Belum ada catatan. Mulai dengan membuat catatan pertama.';
    } else {
      ringkasan = '${catatanVm.catatan.length} catatan tersimpan.';
    }

    return Scaffold(
      appBar: umAppBar('StudyLog', actions: const [IndikatorRealtime()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        children: [
          _HeroCard(
            nama: student.nama,
            prodi: student.programStudi,
            semester: student.semester,
          ),
          const SizedBox(height: 16),
          const StatusSinkronBanner(),
          if (terdekat != null && course != null) ...[
            SectionCard(
              child: Row(
                children: [
                  Icon(
                    terdekat.berlangsung
                        ? Icons.play_circle_fill
                        : Icons.schedule,
                    color: terdekat.berlangsung
                        ? UmColors.green
                        : UmColors.blue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          terdekat.berlangsung
                              ? 'Sedang berlangsung'
                              : 'Kelas berikutnya',
                          style: textTheme.labelMedium
                              ?.copyWith(color: Colors.black54),
                        ),
                        Text(course.nama,
                            style: textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                            '${terdekat.jadwal.label} · ${terdekat.jadwal.ruang}',
                            style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
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
                Text(ringkasan),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.daftar),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Lihat Catatan'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => bukaFormCatatanBaru(context),
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
