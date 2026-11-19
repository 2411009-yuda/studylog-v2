import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../config/pengingat_config.dart';
import '../utils/pengingat_utils.dart';
import '../viewmodels/pengingat_view_model.dart';
import '../widgets/um_widgets.dart';
import 'catatan_form_screen.dart';

/// Semua pengingat (penilaian dosen & catatan kelas yang terlewat) dan
/// tombol uji notifikasi.
class NotifikasiScreen extends StatelessWidget {
  const NotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PengingatViewModel>();
    final textTheme = Theme.of(context).textTheme;
    final daftar = vm.daftar;

    return Scaffold(
      appBar: umAppBar('Notifikasi'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        children: [
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: daftar.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: UmColors.green),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                              'Tidak ada yang terlewat. Semua penilaian dan '
                              'catatan kelas sudah lengkap.'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      for (final p in daftar)
                        ListTile(
                          leading: Icon(
                            p.jenis == JenisPengingat.penilaian
                                ? Icons.star_outline
                                : Icons.edit_note,
                            color: UmColors.blue,
                          ),
                          title: Text(p.judul),
                          subtitle: Text(p.detail),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _buka(context, p),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Uji notifikasi',
                    style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: UmColors.navy)),
                const SizedBox(height: 4),
                Text(
                  'Pengingat otomatis dikirim setiap hari pukul '
                  '${jamPengingatBawaan.toString().padLeft(2, '0')}:'
                  '${menitPengingatBawaan.toString().padLeft(2, '0')}. '
                  'Tekan tombol di bawah untuk mencoba notifikasi sekarang.',
                  style: textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _uji(context),
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Uji notifikasi'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uji(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final terkirim = await context.read<PengingatViewModel>().ujiNotifikasi();
    messenger.showSnackBar(SnackBar(
      content: Text(terkirim
          ? 'Notifikasi uji dikirim. Cek bilah notifikasi perangkat.'
          : 'Notifikasi tidak dapat ditampilkan. Pastikan izin notifikasi '
              'StudyLog aktif di Pengaturan perangkat.'),
    ));
  }

  void _buka(BuildContext context, Pengingat p) {
    if (p.jenis == JenisPengingat.penilaian) {
      Navigator.pushNamed(context, AppRoutes.penilaian,
          arguments: p.mataKuliahKode);
    } else {
      Navigator.pushNamed(context, AppRoutes.form,
          arguments: CatatanFormArgs(jadwal: p.jadwal));
    }
  }
}
