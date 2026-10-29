import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../utils/validators.dart';
import '../widgets/um_widgets.dart';

/// Hasil input yang ditampilkan pada Card (hanya di memori / state lokal).
class _HasilInput {
  const _HasilInput({
    required this.mataKuliah,
    required this.topik,
    required this.judul,
    required this.isi,
  });

  final String mataKuliah;
  final String topik;
  final String judul;
  final String isi;
}

/// Milestone 1 (Praktikum 1): form catatan interaktif satu layar.
///
/// Konsep: StatefulWidget, TextEditingController, Form + GlobalKey,
/// validator, setState, SnackBar. Belum ada penyimpanan permanen.
class CatatanFormScreen extends StatefulWidget {
  const CatatanFormScreen({super.key});

  @override
  State<CatatanFormScreen> createState() => _CatatanFormScreenState();
}

class _CatatanFormScreenState extends State<CatatanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mataKuliah = TextEditingController();
  final _topik = TextEditingController();
  final _judul = TextEditingController();
  final _isi = TextEditingController();

  _HasilInput? _hasil;
  bool _berhasil = false;

  @override
  void dispose() {
    _mataKuliah.dispose();
    _topik.dispose();
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  void _simpanSementara() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _hasil = _HasilInput(
        mataKuliah: _mataKuliah.text.trim(),
        topik: _topik.text.trim(),
        judul: _judul.text.trim(),
        isi: _isi.text.trim(),
      );
      _berhasil = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data ditampilkan (belum tersimpan permanen).'),
      ),
    );
  }

  void _bersihkan() {
    _formKey.currentState!.reset();
    _mataKuliah.clear();
    _topik.clear();
    _judul.clear();
    _isi.clear();
    setState(() {
      _hasil = null;
      _berhasil = false;
    });
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: umAppBar('Form Catatan'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Praktikum 1: State & Interaksi',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: UmColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Isi catatan kuliah, lalu tekan "Tampilkan Catatan".'),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            // Setiap perubahan input membuat tombol kembali ke keadaan awal.
            onChanged: () {
              if (_berhasil) setState(() => _berhasil = false);
            },
            child: Column(
              children: [
                _input(_mataKuliah, 'Mata kuliah'),
                const SizedBox(height: 12),
                _input(_topik, 'Topik', validator: validateTopik),
                const SizedBox(height: 12),
                _input(_judul, 'Judul catatan'),
                const SizedBox(height: 12),
                _input(_isi, 'Isi catatan', baris: 4),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _simpanSementara,
            style: _berhasil
                ? FilledButton.styleFrom(backgroundColor: UmColors.green)
                : null,
            icon: Icon(_berhasil ? Icons.check_circle : Icons.save),
            label: Text(_berhasil ? 'Tersimpan Sementara' : 'Tampilkan Catatan'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _bersihkan,
            icon: const Icon(Icons.refresh),
            label: const Text('Bersihkan'),
          ),
          if (_hasil != null) ...[
            const SizedBox(height: 18),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hasil input',
                      style: textTheme.labelLarge?.copyWith(
                        color: UmColors.blue,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 8),
                  Text(_hasil!.judul, style: textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text('${_hasil!.mataKuliah} · ${_hasil!.topik}',
                      style: textTheme.bodySmall
                          ?.copyWith(color: Colors.black54)),
                  const Divider(height: 24),
                  Text(_hasil!.isi),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
