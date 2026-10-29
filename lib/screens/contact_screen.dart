import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../utils/launcher.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/um_widgets.dart';

/// Layar tambahan (tugas Materi 5): Kontak.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.watch<ProfileViewModel>().student;

    return Scaffold(
      appBar: umAppBar('Kontak'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Hubungi ${student.nama}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: UmColors.navy,
                ),
          ),
          const SizedBox(height: 4),
          const Text('Ketuk untuk membuka, ikon salin untuk menyalin tautan.'),
          const SizedBox(height: 16),
          _ContactTile(
            icon: Icons.email_outlined,
            color: UmColors.red,
            title: 'Email kampus',
            value: student.email,
            uri: Uri(scheme: 'mailto', path: student.email),
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.language,
            color: UmColors.blue,
            title: 'Web portofolio',
            value: student.portfolioUrl,
            uri: Uri.parse(student.portfolioUrl),
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.code,
            color: UmColors.navy,
            title: 'GitHub',
            value: student.githubUrl,
            uri: Uri.parse(student.githubUrl),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.uri,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final Uri uri;

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await openExternal(uri);
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka $title')),
      );
    }
  }

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    messenger.showSnackBar(SnackBar(content: Text('$title disalin')));
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(value),
        trailing: IconButton(
          tooltip: 'Salin',
          icon: const Icon(Icons.copy_outlined),
          onPressed: () => _copy(context),
        ),
        onTap: () => _open(context),
      ),
    );
  }
}
