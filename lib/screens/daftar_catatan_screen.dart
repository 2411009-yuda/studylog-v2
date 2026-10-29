import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../viewmodels/catatan_store.dart';
import '../widgets/um_widgets.dart';

/// Daftar Catatan. Membaca CatatanStore lewat Consumer, sehingga daftar
/// otomatis diperbarui saat catatan baru ditambahkan.
class DaftarCatatanScreen extends StatelessWidget {
  const DaftarCatatanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: umAppBar('Daftar Catatan'),
      body: Consumer<CatatanStore>(builder: (context, store, _) {
        if (store.data.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada catatan. Tekan Tambah untuk membuat catatan.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                'Total: ${store.jumlah} catatan',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: UmColors.navy,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            for (final catatan in store.data)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SectionCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: Text(catatan.judul),
                    subtitle:
                        Text('${catatan.mataKuliah} · ${catatan.topik}'),
                    trailing: const Icon(Icons.chevron_right),
                    // Data dikirim seperlunya: cukup id catatan.
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.detail,
                      arguments: catatan.id,
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.form),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}
