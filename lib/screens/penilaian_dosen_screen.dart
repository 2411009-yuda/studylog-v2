import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/course.dart';
import '../models/penilaian_dosen.dart';
import '../viewmodels/catatan_view_model.dart' show StatusSinkron;
import '../viewmodels/mata_kuliah_view_model.dart';
import '../viewmodels/penilaian_view_model.dart';
import '../widgets/um_widgets.dart';

/// Penilaian dosen per pertemuan untuk satu mata kuliah.
class PenilaianDosenScreen extends StatefulWidget {
  const PenilaianDosenScreen({super.key, required this.courseId});

  /// Kode mata kuliah (argumen route).
  final String courseId;

  @override
  State<PenilaianDosenScreen> createState() => _PenilaianDosenScreenState();
}

class _PenilaianDosenScreenState extends State<PenilaianDosenScreen> {
  @override
  void initState() {
    super.initState();
    // Kirim antrian dan tarik data terbaru setiap layar ini dibuka.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PenilaianViewModel>().sinkronkan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final course =
        context.watch<MataKuliahViewModel>().courseByKode(widget.courseId);
    final vm = context.watch<PenilaianViewModel>();
    final textTheme = Theme.of(context).textTheme;

    if (course == null) {
      return Scaffold(
        appBar: umAppBar('Penilaian Dosen'),
        body: const Center(child: Text('Mata kuliah tidak ditemukan')),
      );
    }

    final rata = vm.rataRataMatkul(course.id);
    final terisi = vm.jumlahTerisi(course.id);

    return Scaffold(
      appBar: umAppBar('Penilaian Dosen'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        children: [
          const _StatusBanner(),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.nama,
                    style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: UmColors.navy)),
                const SizedBox(height: 4),
                Text(course.dosen, style: textTheme.bodyMedium),
                const SizedBox(height: 12),
                Text(
                  rata == null
                      ? 'Belum ada penilaian'
                      : 'Rata-rata ${formatSkor(rata)} / $skorMaks · '
                          '${kategoriSkor(rata)}',
                  style: textTheme.titleSmall?.copyWith(color: UmColors.blue),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: terisi / jumlahPertemuan,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Text('$terisi dari $jumlahPertemuan pertemuan dinilai',
                    style: textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Pertemuan',
              style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: UmColors.navy)),
          const SizedBox(height: 8),
          for (var p = 1; p <= jumlahPertemuan; p++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PertemuanTile(course: course, pertemuan: p),
            ),
        ],
      ),
    );
  }
}

/// Pita status sinkronisasi penilaian. Tidak tampil jika semuanya normal.
class _StatusBanner extends StatelessWidget {
  const _StatusBanner();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PenilaianViewModel>();

    final IconData ikon;
    final String teks;
    final bool tombol;

    if (vm.status == StatusSinkron.offline) {
      ikon = Icons.cloud_off;
      teks = vm.tertunda > 0
          ? 'Offline · ${vm.tertunda} penilaian menunggu dikirim'
          : 'Offline · menampilkan data tersimpan di perangkat';
      tombol = true;
    } else if (vm.ditolak > 0) {
      ikon = Icons.error_outline;
      teks = '${vm.ditolak} penilaian ditolak server'
          '${vm.pesanSinkron == null ? '' : ': ${vm.pesanSinkron}'}';
      tombol = false;
    } else if (vm.status == StatusSinkron.menyinkronkan && vm.tertunda > 0) {
      ikon = Icons.sync;
      teks = 'Mengirim ${vm.tertunda} penilaian...';
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
              onPressed: () => context.read<PenilaianViewModel>().sinkronkan(),
              child: const Text('Kirim ulang'),
            ),
        ],
      ),
    );
  }
}

class _PertemuanTile extends StatelessWidget {
  const _PertemuanTile({required this.course, required this.pertemuan});

  final Course course;
  final int pertemuan;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PenilaianViewModel>();
    final nilai = vm.untuk(course.id, pertemuan);

    var subtitle = 'Belum dinilai';
    if (nilai != null) {
      subtitle = '${formatSkor(nilai.rataRata)} · '
          '${kategoriSkor(nilai.rataRata)}';
      if (nilai.galat != null) {
        subtitle += ' · ditolak server';
      } else if (nilai.menunggu) {
        subtitle += ' · menunggu dikirim';
      }
    }

    final IconData trailing;
    if (nilai == null) {
      trailing = Icons.rate_review_outlined;
    } else if (nilai.galat != null) {
      trailing = Icons.error_outline;
    } else if (nilai.menunggu) {
      trailing = Icons.cloud_upload_outlined;
    } else {
      trailing = Icons.edit_outlined;
    }

    return SectionCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          backgroundColor: nilai == null ? Colors.black12 : UmColors.green,
          child: nilai == null
              ? Text('$pertemuan',
                  style: const TextStyle(color: UmColors.navy))
              : const Icon(Icons.check, color: Colors.white),
        ),
        title: Text('Pertemuan $pertemuan'),
        subtitle: Text(subtitle),
        trailing: Icon(trailing),
        onTap: () => _bukaForm(context, vm, nilai),
      ),
    );
  }

  Future<void> _bukaForm(
    BuildContext context,
    PenilaianViewModel vm,
    PenilaianDosen? awal,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final pesan = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FormPenilaianSheet(
        vm: vm,
        course: course,
        pertemuan: pertemuan,
        awal: awal,
      ),
    );
    if (pesan != null) {
      messenger.showSnackBar(SnackBar(content: Text(pesan)));
    }
  }
}

class _FormPenilaianSheet extends StatefulWidget {
  const _FormPenilaianSheet({
    required this.vm,
    required this.course,
    required this.pertemuan,
    required this.awal,
  });

  final PenilaianViewModel vm;
  final Course course;
  final int pertemuan;
  final PenilaianDosen? awal;

  @override
  State<_FormPenilaianSheet> createState() => _FormPenilaianSheetState();
}

class _FormPenilaianSheetState extends State<_FormPenilaianSheet> {
  late final Map<String, int> _skor;
  late final TextEditingController _komentarCtrl;

  @override
  void initState() {
    super.initState();
    _skor = Map<String, int>.from(widget.awal?.skor ?? const {});
    _komentarCtrl = TextEditingController(text: widget.awal?.komentar ?? '');
  }

  @override
  void dispose() {
    _komentarCtrl.dispose();
    super.dispose();
  }

  // Penyimpanan ke perangkat cepat dan tidak menunggu jaringan.
  Future<void> _simpan() async {
    await widget.vm.simpan(
      mataKuliahId: widget.course.id,
      pertemuan: widget.pertemuan,
      skor: _skor,
      komentar: _komentarCtrl.text,
    );
    if (mounted) Navigator.of(context).pop('Penilaian disimpan');
  }

  Future<void> _hapus() async {
    await widget.vm.hapus(widget.course.id, widget.pertemuan);
    if (mounted) Navigator.of(context).pop('Penilaian dihapus');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lengkap = widget.vm.validateSkor(_skor) == null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Penilaian Pertemuan ${widget.pertemuan}',
                style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold, color: UmColors.navy)),
            const SizedBox(height: 2),
            Text(widget.course.dosen, style: textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('Skala 1 (sangat kurang) sampai 5 (sangat baik)',
                style: textTheme.bodySmall?.copyWith(color: Colors.black54)),
            const SizedBox(height: 12),
            for (final aspek in aspekPenilaian) ...[
              Text(aspek.label,
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text(aspek.keterangan,
                  style: textTheme.bodySmall?.copyWith(color: Colors.black54)),
              Row(
                children: [
                  for (var n = skorMin; n <= skorMaks; n++)
                    IconButton(
                      key: Key('skor-${aspek.kode}-$n'),
                      tooltip: '${aspek.label}: $n (${labelSkor[n]})',
                      onPressed: () => setState(() => _skor[aspek.kode] = n),
                      icon: Icon(
                        (_skor[aspek.kode] ?? 0) >= n
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: UmColors.yellow,
                        size: 32,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _skor[aspek.kode] == null
                          ? 'Belum dinilai'
                          : labelSkor[_skor[aspek.kode]]!,
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _komentarCtrl,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Komentar atau saran (opsional)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.awal != null)
                  TextButton(
                    onPressed: _hapus,
                    child: const Text('Hapus',
                        style: TextStyle(color: UmColors.red)),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
                  onPressed: lengkap ? _simpan : null,
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
