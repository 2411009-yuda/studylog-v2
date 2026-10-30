import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../utils/navigasi_catatan.dart';
import '../viewmodels/catatan_view_model.dart';
import '../widgets/um_widgets.dart';

/// Daftar Catatan. Membaca CatatanViewModel lewat Consumer, sehingga daftar
/// otomatis diperbarui setelah tambah/ubah/hapus. Tarik ke bawah = muat ulang.
class DaftarCatatanScreen extends StatelessWidget {
  const DaftarCatatanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: umAppBar('Daftar Catatan'),
      body: Consumer<CatatanViewModel>(builder: (context, vm, _) {
        if (vm.isLoading && vm.catatan.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.error != null && vm.catatan.isEmpty) {
          return Center(
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
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(160, 44)),
                    onPressed: vm.muatCatatan,
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          );
        }
        if (vm.catatan.isEmpty) {
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
        return RefreshIndicator(
          onRefresh: vm.muatCatatan,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  'Total: ${vm.catatan.length} catatan',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: UmColors.navy,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              for (final catatan in vm.catatan)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: SectionCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Text(catatan.judul),
                      subtitle: Text(
                          '${catatan.mataKuliahNama} · ${catatan.topik}'),
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
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => bukaFormCatatanBaru(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}
