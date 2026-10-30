import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../utils/sinkron_aksi.dart';
import '../viewmodels/catatan_view_model.dart';

/// Pita status sinkronisasi. Tidak tampil jika semuanya normal.
class StatusSinkronBanner extends StatelessWidget {
  const StatusSinkronBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatatanViewModel>();

    final IconData ikon;
    final String teks;
    final bool tombol;

    if (vm.status == StatusSinkron.offline) {
      ikon = Icons.cloud_off;
      teks = vm.tertunda > 0
          ? 'Offline · ${vm.tertunda} perubahan menunggu sinkron'
          : 'Offline · menampilkan data tersimpan di perangkat';
      tombol = true;
    } else if (vm.ditolak > 0) {
      ikon = Icons.error_outline;
      teks = '${vm.ditolak} perubahan ditolak server'
          '${vm.pesanSinkron == null ? '' : ': ${vm.pesanSinkron}'}';
      tombol = false;
    } else if (vm.status == StatusSinkron.menyinkronkan && vm.tertunda > 0) {
      ikon = Icons.sync;
      teks = 'Menyinkronkan ${vm.tertunda} perubahan...';
      tombol = false;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: UmColors.yellow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(ikon, size: 20, color: UmColors.navy),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              teks,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: UmColors.navy, fontWeight: FontWeight.w600),
            ),
          ),
          if (tombol)
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(64, 36),
                foregroundColor: UmColors.navy,
              ),
              onPressed: () => sinkronSemua(context),
              child: const Text('Sinkronkan'),
            ),
        ],
      ),
    );
  }
}
