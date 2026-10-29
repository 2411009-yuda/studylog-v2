import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/validators.dart';
import '../viewmodels/catatan_store.dart';
import '../widgets/um_widgets.dart';

/// Form Tambah Catatan (M1 dikembangkan pada M2).
///
/// Validasi dan controller sama seperti Praktikum 1. Bedanya, data kini
/// dikirim ke [CatatanStore] lalu halaman ditutup dengan Navigator.pop,
/// sehingga pengguna kembali ke halaman sebelumnya.
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

    context.read<CatatanStore>().tambah(
          mataKuliah: _mataKuliah.text,
          topik: _topik.text,
          judul: _judul.text,
          isi: _isi.text,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Catatan disimpan sementara di memori.')),
    );
    Navigator.pop(context);
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
    return Scaffold(
      appBar: umAppBar('Tambah Catatan'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: [
                _input(_mataKuliah, 'Mata kuliah'),
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
            onPressed: _simpanSementara,
            icon: const Icon(Icons.save),
            label: const Text('Simpan Sementara'),
          ),
        ],
      ),
    );
  }
}
