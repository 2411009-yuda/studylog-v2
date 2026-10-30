import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/catatan.dart';
import '../models/jadwal.dart';
import '../utils/validators.dart';
import '../viewmodels/catatan_view_model.dart';
import '../viewmodels/mata_kuliah_view_model.dart';
import '../widgets/um_widgets.dart';

/// Argumen route form catatan.
/// - [awal]   : catatan yang diubah (mode ubah). Null = mode tambah.
/// - [jadwal] : jadwal yang dipakai mengisi mata kuliah otomatis (mode tambah).
class CatatanFormArgs {
  const CatatanFormArgs({this.awal, this.jadwal});

  final Catatan? awal;
  final Jadwal? jadwal;
}

/// Form tambah/ubah catatan. Mata kuliah dipilih dari database (dropdown).
class CatatanFormScreen extends StatefulWidget {
  const CatatanFormScreen({super.key, this.args});

  final CatatanFormArgs? args;

  @override
  State<CatatanFormScreen> createState() => _CatatanFormScreenState();
}

class _CatatanFormScreenState extends State<CatatanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _topik;
  late final TextEditingController _judul;
  late final TextEditingController _isi;
  int? _mataKuliahId;
  bool _menyimpan = false;

  Catatan? get _awal => widget.args?.awal;
  Jadwal? get _jadwalOtomatis => _awal == null ? widget.args?.jadwal : null;

  @override
  void initState() {
    super.initState();
    _topik = TextEditingController(text: _awal?.topik ?? '');
    _judul = TextEditingController(text: _awal?.judul ?? '');
    _isi = TextEditingController(text: _awal?.isi ?? '');
    _mataKuliahId = _awal?.mataKuliahId ?? _jadwalOtomatis?.mataKuliahId;
  }

  @override
  void dispose() {
    _topik.dispose();
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate() || _menyimpan) return;
    setState(() => _menyimpan = true);

    final awal = _awal;
    final course =
        context.read<MataKuliahViewModel>().courseById(_mataKuliahId!);
    final kode = course?.kode ?? awal?.mataKuliahKode ?? '';
    final namaMk = course?.nama ?? awal?.mataKuliahNama ?? '';

    // Mengubah: copyWith mempertahankan id lokal, clientId, dan serverId.
    final data = awal == null
        ? Catatan(
            mataKuliahId: _mataKuliahId!,
            mataKuliahKode: kode,
            mataKuliahNama: namaMk,
            topik: _topik.text.trim(),
            judul: _judul.text.trim(),
            isi: _isi.text.trim(),
            tanggal: DateTime.now(),
          )
        : awal.copyWith(
            mataKuliahId: _mataKuliahId!,
            mataKuliahKode: kode,
            mataKuliahNama: namaMk,
            topik: _topik.text.trim(),
            judul: _judul.text.trim(),
            isi: _isi.text.trim(),
          );

    final vm = context.read<CatatanViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Hanya menulis ke penyimpanan lokal; pengiriman ke server menyusul.
      if (awal == null) {
        await vm.tambahCatatan(data);
      } else {
        await vm.ubahCatatan(data);
      }
      if (!mounted) return;
      final offline = vm.status == StatusSinkron.offline;
      messenger.showSnackBar(SnackBar(
        content: Text(offline
            ? 'Disimpan offline. Akan disinkronkan saat terhubung.'
            : awal == null
                ? 'Catatan tersimpan.'
                : 'Catatan diperbarui.'),
      ));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  Widget _input(
    TextEditingController controller,
    String label, {
    int baris = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: baris,
      decoration: InputDecoration(labelText: label),
      validator: validator ?? (nilai) => validateWajibIsi(nilai, label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mkVm = context.watch<MataKuliahViewModel>();
    final courses = mkVm.courses;
    final terpilih =
        courses.any((c) => c.id == _mataKuliahId) ? _mataKuliahId : null;
    final jadwal = _jadwalOtomatis;

    return Scaffold(
      appBar: umAppBar(_awal == null ? 'Tambah Catatan' : 'Ubah Catatan'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                DropdownButtonFormField<int>(
                  value: terpilih,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Mata kuliah'),
                  items: [
                    for (final c in courses)
                      DropdownMenuItem(
                        value: c.id,
                        child: Text(c.nama, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: courses.isEmpty
                      ? null
                      : (id) => setState(() => _mataKuliahId = id),
                  validator: (id) =>
                      id == null ? 'Mata kuliah wajib dipilih' : null,
                ),
                if (jadwal != null && terpilih == jadwal.mataKuliahId)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            size: 16, color: UmColors.blue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Terisi otomatis dari jadwal: ${jadwal.label}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: UmColors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (mkVm.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Memuat mata kuliah...'),
                    ),
                  ),
                if (mkVm.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            mkVm.error!,
                            style: const TextStyle(color: UmColors.red),
                          ),
                        ),
                        TextButton(
                          onPressed: mkVm.muat,
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                _input(_topik, 'Topik', validator: validateTopik),
                const SizedBox(height: 12),
                _input(_judul, 'Judul catatan'),
                const SizedBox(height: 12),
                _input(_isi, 'Isi catatan', baris: 5),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _menyimpan ? null : _simpan,
            icon: const Icon(Icons.save),
            label: Text(_menyimpan ? 'Menyimpan...' : 'Simpan'),
          ),
        ],
      ),
    );
  }
}
