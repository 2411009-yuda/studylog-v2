import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../utils/ekspor_aksi.dart';
import '../utils/ekspor_teks.dart';
import '../utils/navigasi_catatan.dart';
import '../utils/sinkron_aksi.dart';
import '../utils/urutan_catatan.dart';
import '../viewmodels/catatan_view_model.dart';
import '../widgets/indikator_realtime.dart';
import '../widgets/status_sinkron_banner.dart';
import '../widgets/um_widgets.dart';

/// Daftar Catatan. Membaca CatatanViewModel lewat Consumer, sehingga daftar
/// otomatis diperbarui setelah tambah/ubah/hapus. Tarik ke bawah = muat ulang.
class DaftarCatatanScreen extends StatelessWidget {
  const DaftarCatatanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: umAppBar(
        'Daftar Catatan',
        actions: [
          const IndikatorRealtime(),
          IconButton(
            tooltip: 'Sinkronkan',
            icon: const Icon(Icons.sync),
            onPressed: () => sinkronSemua(context),
          ),
        ],
      ),
      body: Column(children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: StatusSinkronBanner(),
        ),
        Expanded(child: Consumer<CatatanViewModel>(builder: (context, vm, _) {
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
          onRefresh: () => sinkronSemua(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total: ${vm.catatan.length} catatan',
                            style:
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: UmColors.navy,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          Text(
                            'Urutan: ${vm.urutan.label}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<UrutanCatatan>(
                      tooltip: 'Urutkan',
                      icon: const Icon(Icons.sort),
                      initialValue: vm.urutan,
                      onSelected: vm.ubahUrutan,
                      itemBuilder: (_) => [
                        for (final u in UrutanCatatan.values)
                          PopupMenuItem(value: u, child: Text(u.label)),
                      ],
                    ),
                    PopupMenuButton<_AksiEkspor>(
                      tooltip: 'Ekspor',
                      icon: const Icon(Icons.ios_share),
                      onSelected: (aksi) => _ekspor(context, vm, aksi),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: _AksiEkspor.salin,
                          child: Text('Salin semua'),
                        ),
                        PopupMenuItem(
                          value: _AksiEkspor.bagikan,
                          child: Text('Bagikan semua'),
                        ),
                      ],
                    ),
                  ],
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (catatan.menunggu)
                            const Tooltip(
                              message: 'Menunggu sinkron',
                              child: Icon(Icons.cloud_upload_outlined,
                                  size: 20, color: UmColors.blue),
                            ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
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
      })),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => bukaFormCatatanBaru(context),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
    );
  }
}

enum _AksiEkspor { salin, bagikan }

void _ekspor(BuildContext context, CatatanViewModel vm, _AksiEkspor aksi) {
  // Mengikuti urutan yang sedang dipilih pengguna.
  final teks = eksporSemua(
    vm.catatan,
    waktu: DateTime.now(),
    urutan: vm.urutan.label,
  );
  switch (aksi) {
    case _AksiEkspor.salin:
      salinTeks(
        context,
        teks,
        pesan: 'Semua catatan (${vm.catatan.length}) disalin ke clipboard.',
      );
    case _AksiEkspor.bagikan:
      bagikanTeks(context, teks, subjek: 'Catatan StudyLog');
  }
}
