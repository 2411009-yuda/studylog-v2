import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/um_widgets.dart';
import 'edit_profile_dialog.dart';

/// Layar 2: Profil. Menampilkan data mahasiswa dari ViewModel.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.watch<ProfileViewModel>().student;

    return Scaffold(
      appBar: umAppBar('Profil'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Stack(
              children: [
                const ProfileAvatar(radius: 56),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Tooltip(
                    message: 'Ganti foto',
                    child: Material(
                      color: UmColors.yellow,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _showPhotoSheet(context),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.camera_alt,
                              size: 20, color: UmColors.navy),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            student.nama,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: UmColors.navy,
                ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Chip(
              avatar: const Icon(Icons.check_circle,
                  size: 18, color: UmColors.green),
              label: Text('Mahasiswa ${student.status}'),
              backgroundColor: const Color(0xFFE6F6EE),
              side: BorderSide.none,
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              children: [
                InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'NIM',
                    value: student.nim),
                const Divider(height: 1),
                InfoRow(
                    icon: Icons.school_outlined,
                    label: 'Program Studi',
                    value: student.programStudi),
                const Divider(height: 1),
                InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Semester',
                    value: '${student.semester}'),
                const Divider(height: 1),
                InfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: student.email),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _editProfile(context),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Profil'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.contact),
            icon: const Icon(Icons.contact_mail_outlined),
            label: const Text('Lihat Kontak'),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final vm = context.read<ProfileViewModel>();
    final messenger = ScaffoldMessenger.of(context);

    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => EditProfileDialog(
        initialNama: vm.student.nama,
        initialProdi: vm.student.programStudi,
      ),
    );
    if (result == null) return; // dibatalkan

    vm.updateProfile(nama: result[0], programStudi: result[1]);
    messenger.showSnackBar(
      const SnackBar(content: Text('Profil berhasil disimpan')),
    );
  }
}

void _showPhotoSheet(BuildContext context) {
  final vm = context.read<ProfileViewModel>();
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari galeri'),
            onTap: () {
              Navigator.pop(sheetContext);
              _pickPhoto(context, ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Ambil dengan kamera'),
            onTap: () {
              Navigator.pop(sheetContext);
              _pickPhoto(context, ImageSource.camera);
            },
          ),
          if (vm.hasCustomPhoto)
            ListTile(
              leading: const Icon(Icons.restore, color: UmColors.red),
              title: const Text('Kembalikan foto bawaan'),
              onTap: () {
                Navigator.pop(sheetContext);
                vm.resetPhoto();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Foto bawaan dikembalikan')),
                );
              },
            ),
        ],
      ),
    ),
  );
}

Future<void> _pickPhoto(BuildContext context, ImageSource source) async {
  final vm = context.read<ProfileViewModel>();
  final messenger = ScaffoldMessenger.of(context);

  final result = await vm.changePhoto(source);

  switch (result) {
    case PhotoResult.changed:
      messenger.showSnackBar(
        const SnackBar(content: Text('Foto profil diperbarui')),
      );
    case PhotoResult.failed:
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat mengambil foto. Periksa izin akses.'),
        ),
      );
    case PhotoResult.cancelled:
      break;
  }
}

