import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/profile_viewmodel.dart';

/// Dialog edit nama & program studi. Mengembalikan [nama, prodi] jika disimpan.
class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({
    super.key,
    required this.initialNama,
    required this.initialProdi,
  });

  final String initialNama;
  final String initialProdi;

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _prodiCtrl;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.initialNama);
    _prodiCtrl = TextEditingController(text: widget.initialProdi);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _prodiCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(<String>[
      _namaCtrl.text.trim(),
      _prodiCtrl.text.trim(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ProfileViewModel>();
    // Tombol Simpan aktif hanya saat semua input valid.
    final isValid = vm.validateNama(_namaCtrl.text) == null &&
        vm.validateProdi(_prodiCtrl.text) == null;

    return AlertDialog(
      title: const Text('Edit Profil'),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama'),
                textInputAction: TextInputAction.next,
                validator: vm.validateNama,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prodiCtrl,
                decoration: const InputDecoration(labelText: 'Program Studi'),
                textInputAction: TextInputAction.done,
                validator: vm.validateProdi,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => isValid ? _submit() : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: isValid ? _submit : null,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
