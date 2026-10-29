import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../viewmodels/catatan_store.dart';
import '../widgets/um_widgets.dart';

/// Detail Catatan. Menerima [id] dari route, lalu mencari data di store.
class DetailCatatanScreen extends StatelessWidget {
  const DetailCatatanScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    final catatan = context.watch<CatatanStore>().byId(id);
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
            catatan.mataKuliah,
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
          Text('Dibuat: ${catatan.tanggalLabel}'),
          const Divider(height: 32),
          Text(catatan.isi),
        ],
      ),
    );
  }
}
