import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/student.dart';
import '../viewmodels/profile_viewmodel.dart';

/// Dialog edit seluruh data profil. Mengembalikan [Student] baru jika disimpan.
class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({super.key, required this.initial});

  final Student initial;

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _nimCtrl;
  late final TextEditingController _prodiCtrl;
  late final TextEditingController _statusCtrl;
  late final TextEditingController _semesterCtrl;
  late final TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _namaCtrl = TextEditingController(text: s.nama);
    _nimCtrl = TextEditingController(text: s.nim);
    _prodiCtrl = TextEditingController(text: s.programStudi);
    _statusCtrl = TextEditingController(text: s.status);
    _semesterCtrl = TextEditingController(text: '${s.semester}');
    _emailCtrl = TextEditingController(text: s.email);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _nimCtrl.dispose();
    _prodiCtrl.dispose();
    _statusCtrl.dispose();
    _semesterCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      widget.initial.copyWith(
        nama: _namaCtrl.text.trim(),
        nim: _nimCtrl.text.trim(),
        programStudi: _prodiCtrl.text.trim(),
        status: _statusCtrl.text.trim(),
        semester: int.parse(_semesterCtrl.text.trim()),
        email: _emailCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ProfileViewModel>();
    // Tombol Simpan aktif hanya saat semua input valid.
    final isValid = vm.validateNama(_namaCtrl.text) == null &&
        vm.validateNim(_nimCtrl.text) == null &&
        vm.validateProdi(_prodiCtrl.text) == null &&
        vm.validateStatus(_statusCtrl.text) == null &&
        vm.validateSemester(_semesterCtrl.text) == null &&
        vm.validateEmail(_emailCtrl.text) == null;

    Widget field({
      required TextEditingController controller,
      required String label,
      required String? Function(String?) validator,
      TextInputType? keyboardType,
      bool last = false,
    }) {
      return Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 16),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          keyboardType: keyboardType,
          textInputAction: last ? TextInputAction.done : TextInputAction.next,
          validator: validator,
          onChanged: (_) => setState(() {}),
          onFieldSubmitted: last ? (_) => isValid ? _submit() : null : null,
        ),
      );
    }

    return AlertDialog(
      title: const Text('Edit Profil'),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              field(
                  controller: _namaCtrl,
                  label: 'Nama',
                  validator: vm.validateNama),
              field(
                  controller: _nimCtrl,
                  label: 'NIM',
                  validator: vm.validateNim),
              field(
                  controller: _prodiCtrl,
                  label: 'Program Studi',
                  validator: vm.validateProdi),
              field(
                  controller: _statusCtrl,
                  label: 'Status',
                  validator: vm.validateStatus),
              field(
                  controller: _semesterCtrl,
                  label: 'Semester',
                  validator: vm.validateSemester,
                  keyboardType: TextInputType.number),
              field(
                  controller: _emailCtrl,
                  label: 'Email',
                  validator: vm.validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  last: true),
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
