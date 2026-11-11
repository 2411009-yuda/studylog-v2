import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../models/catatan.dart';
import '../utils/ekspor_aksi.dart';
import '../utils/ekspor_teks.dart';
import '../utils/kelompok_catatan.dart';
import '../utils/navigasi_catatan.dart';
import '../utils/sinkron_aksi.dart';
import '../utils/urutan_catatan.dart';
import '../viewmodels/catatan_view_model.dart';
import '../widgets/indikator_realtime.dart';
import '../widgets/status_sinkron_banner.dart';
import '../widgets/um_widgets.dart';

/// Daftar Catatan. Membaca CatatanViewModel lewat Consumer, sehingga daftar
/// otomatis diperbarui setelah tambah/ubah/hapus. Tarik ke bawah = muat ulang.
/// Bisa dicari, difilter per mata kuliah, dan dikelompokkan per mata kuliah.
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
        // Kolom cari + filter mata kuliah hanya muncul jika sudah ada catatan.
        Consumer<CatatanViewModel>(
          builder: (_, vm, _) => vm.catatan.isEmpty
              ? const SizedBox.shrink()
              : Column(children: [
                  _KolomCari(kueri: vm.kueri),
                  _BarisMataKuliah(vm: vm),
                ]),
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
          final tampil = vm.catatanTampil;
          return RefreshIndicator(
            onRefresh: () => sinkronSemua(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                              vm.sedangMenyaring
                                  ? 'Ditemukan: ${tampil.length} dari '
                                      '${vm.catatan.length} catatan'
                                  : 'Total: ${vm.catatan.length} catatan',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
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
                      IconButton(
                        tooltip: vm.kelompokkan
                            ? 'Tampilkan tanpa kelompok'
                            : 'Kelompokkan per mata kuliah',
                        isSelected: vm.kelompokkan,
                        icon: const Icon(Icons.view_agenda_outlined),
                        selectedIcon: const Icon(Icons.view_agenda),
                        onPressed: () => vm.ubahKelompokkan(!vm.kelompokkan),
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
                if (vm.sedangMenyaring && tampil.isEmpty)
                  _TidakAdaHasil(vm: vm)
                else if (vm.kelompokkan)
                  for (final kelompok in vm.kelompokTampil) ...[
                    _JudulKelompok(kelompok.mataKuliah),
                    for (final catatan in kelompok.catatan)
                      _ItemCatatan(catatan, tampilkanMataKuliah: false),
                  ]
                else
                  for (final catatan in tampil) _ItemCatatan(catatan),
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

/// Satu catatan pada daftar. Pada tampilan berkelompok nama mata kuliah sudah
/// ada di judul kelompok, jadi subtitle cukup menampilkan topik.
class _ItemCatatan extends StatelessWidget {
  const _ItemCatatan(this.catatan, {this.tampilkanMataKuliah = true});

  final Catatan catatan;
  final bool tampilkanMataKuliah;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SectionCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(catatan.judul),
          subtitle: Text(tampilkanMataKuliah
              ? '${catatan.mataKuliahNama} · ${catatan.topik}'
              : catatan.topik),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (catatan.menunggu)
                const Tooltip(
                  message: 'Menunggu sinkron',
                  child: Icon(Icons.cloud_upload_outlined,
                      size: 20, color: UmColors.blue),
                ),
              IconButton(
                tooltip: catatan.favorit
                    ? 'Hapus dari favorit'
                    : 'Tandai favorit',
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  catatan.favorit ? Icons.star : Icons.star_border,
                  color: catatan.favorit ? Colors.amber.shade700 : null,
                ),
                onPressed: () => context
                    .read<CatatanViewModel>()
                    .setFavorit(catatan.id!, !catatan.favorit),
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
    );
  }
}

class _JudulKelompok extends StatelessWidget {
  const _JudulKelompok(this.mk);

  final RingkasMataKuliah mk;

  @override
  Widget build(BuildContext context) {
    final kode = mk.kode.isEmpty ? '' : ' (${mk.kode})';
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(children: [
        const Icon(Icons.folder_outlined, size: 18, color: UmColors.navy),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${mk.label}$kode',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: UmColors.navy,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Text('${mk.jumlah} catatan',
            style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

class _TidakAdaHasil extends StatelessWidget {
  const _TidakAdaHasil({required this.vm});

  final CatatanViewModel vm;

  @override
  Widget build(BuildContext context) {
    final kata = vm.kueri.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 48, color: Colors.black45),
          const SizedBox(height: 12),
          Text(
            kata.isNotEmpty
                ? 'Tidak ada catatan yang cocok dengan "$kata".'
                : vm.hanyaFavorit
                    ? 'Belum ada catatan favorit yang cocok dengan filter.'
                    : 'Tidak ada catatan untuk mata kuliah ini.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: vm.resetPenyaring,
            child: const Text('Hapus pencarian & filter'),
          ),
        ],
      ),
    );
  }
}

/// Baris chip filter: Semua, Favorit, lalu satu chip per mata kuliah.
/// Favorit dan mata kuliah bisa digabung. Menekan chip yang sedang aktif melepas filter.
class _BarisMataKuliah extends StatelessWidget {
  const _BarisMataKuliah({required this.vm});

  final CatatanViewModel vm;

  @override
  Widget build(BuildContext context) {
    final aktif = vm.filterMataKuliahId;
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('Semua (${vm.catatan.length})'),
              selected: aktif == null,
              onSelected: (_) => vm.ubahFilterMataKuliah(null),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(
                Icons.star,
                size: 18,
                color: vm.hanyaFavorit ? null : Colors.amber.shade700,
              ),
              label: Text('Favorit (${vm.jumlahFavorit})'),
              selected: vm.hanyaFavorit,
              onSelected: vm.ubahHanyaFavorit,
            ),
          ),
          for (final mk in vm.daftarMataKuliah)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${mk.label} (${mk.jumlah})'),
                selected: aktif == mk.id,
                onSelected: (_) =>
                    vm.ubahFilterMataKuliah(aktif == mk.id ? null : mk.id),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kolom pencarian. Controller dimiliki widget ini dan disamakan dengan
/// [kueri] dari ViewModel, sehingga tombol "Hapus pencarian & filter" di
/// tempat lain ikut mengosongkan kolom ini.
class _KolomCari extends StatefulWidget {
  const _KolomCari({required this.kueri});

  final String kueri;

  @override
  State<_KolomCari> createState() => _KolomCariState();
}

class _KolomCariState extends State<_KolomCari> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.kueri);

  @override
  void didUpdateWidget(covariant _KolomCari lama) {
    super.didUpdateWidget(lama);
    if (widget.kueri != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.kueri,
        selection: TextSelection.collapsed(offset: widget.kueri.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<CatatanViewModel>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        controller: _controller,
        textInputAction: TextInputAction.search,
        onChanged: vm.ubahKueri,
        decoration: InputDecoration(
          hintText: 'Cari judul, topik, isi, atau mata kuliah',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (_, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Hapus pencarian',
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      vm.ubahKueri('');
                    },
                  ),
          ),
        ),
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
