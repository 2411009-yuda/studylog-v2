import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../screens/catatan_form_screen.dart';
import '../utils/pengingat_utils.dart';
import '../viewmodels/pengingat_view_model.dart';
import 'um_widgets.dart';

/// Kartu "Perlu perhatian" di Beranda: penilaian dosen dan catatan kelas yang
/// terlewat. Tidak tampil jika tidak ada yang terlewat.
class KartuPengingat extends StatelessWidget {
  const KartuPengingat({super.key});

  static const _maks = 4;

  @override
  Widget build(BuildContext context) {
    final daftar = context.watch<PengingatViewModel>().daftar;
    if (daftar.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final tampil = daftar.take(_maks).toList();
    final sisa = daftar.length - tampil.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionCard(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      color: UmColors.red),
                  const SizedBox(width: 8),
                  Text('Perlu perhatian',
                      style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: UmColors.navy)),
                ],
              ),
            ),
            for (final p in tampil)
              ListTile(
                dense: true,
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
            if (sisa > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text('+ $sisa lainnya', style: textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
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
