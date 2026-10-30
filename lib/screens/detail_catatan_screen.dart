import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../viewmodels/catatan_view_model.dart';
import '../widgets/um_widgets.dart';
import 'catatan_form_screen.dart';

/// Detail Catatan. Menerima [id] dari route, lalu mencari data di ViewModel.
class DetailCatatanScreen extends StatelessWidget {
  const DetailCatatanScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CatatanViewModel>();
    final catatan = vm.byId(id);
    final textTheme = Theme.of(context).textTheme;

    if (catatan == null) {
      return Scaffold(
        appBar: umAppBar('Detail Catatan'),
        body: const Center(child: Text('Catatan tidak ditemukan.')),
      );
    }

    return Scaffold(
      appBar: umAppBar('Detail Catatan'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            catatan.mataKuliahNama,
            style: textTheme.labelLarge?.copyWith(color: UmColors.blue),
          ),
          const SizedBox(height: 8),
          Text(
            catatan.judul,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: UmColors.navy,
            ),
          ),
          const SizedBox(height: 8),
          Text('Topik: ${catatan.topik}'),
          Text('Dibuat: ${catatan.tanggalWaktuLabel}'),
          const Divider(height: 32),
          Text(catatan.isi),
          const SizedBox(height: 28),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.pushNamed(
              context,
              AppRoutes.form,
              arguments: CatatanFormArgs(awal: catatan),
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Ubah'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _konfirmasiHapus(context, vm, catatan.id!),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _konfirmasiHapus(
    BuildContext context,
    CatatanViewModel vm,
    int id,
  ) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: const Text('Catatan yang dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 40)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin != true || !context.mounted) return;
    try {
      await vm.hapusCatatan(id);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }
}
