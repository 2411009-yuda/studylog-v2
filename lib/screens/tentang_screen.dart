import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../config/app_info.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../widgets/um_widgets.dart';

/// Halaman "Tentang Aplikasi" (tugas pengayaan Praktikum 2), dibuka dari
/// Beranda dengan Navigator.push sehingga tombol kembali menuju Beranda.
class TentangScreen extends StatelessWidget {
  const TentangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final student = context.watch<ProfileViewModel>().student;
    final textTheme = Theme.of(context).textTheme;

    Widget judul(String teks) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            teks,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: UmColors.navy,
            ),
          ),
        );

    Widget baris(String label, String nilai) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 104,
                child: Text(label,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: Colors.black54)),
              ),
              Expanded(child: Text(nilai)),
            ],
          ),
        );

    return Scaffold(
      appBar: umAppBar('Tentang Aplikasi'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Identitas aplikasi ----
          Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: UmColors.blue,
                child: Icon(Icons.menu_book_rounded,
                    size: 44, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                AppInfo.nama,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: UmColors.navy,
                ),
              ),
              Text(AppInfo.tagline, style: textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                'Versi ${AppInfo.versi}',
                style: textTheme.labelLarge?.copyWith(color: UmColors.blue),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ---- Deskripsi ----
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                judul('Tentang'),
                Text(AppInfo.deskripsi),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- Fitur ----
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                judul('Fitur'),
                for (final f in AppInfo.fitur)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 20, color: UmColors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.judul,
                                  style: textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              Text(f.keterangan,
                                  style: textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- Teknologi ----
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                judul('Teknologi'),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final t in AppInfo.teknologi) Chip(label: Text(t)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- Pengembang (mengikuti data profil) ----
          // SectionCard(
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       judul('Pengembang'),
          //       baris('Nama', student.nama),
          //       baris('NIM', student.nim),
          //       baris('Program studi', student.programStudi),
          //       baris('Institusi', AppInfo.institusi),
          //       baris('Mata kuliah', AppInfo.mataKuliah),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 16),
          // Center(
          //   child: Text(
          //     '© ${AppInfo.tahun} ${AppInfo.institusi}',
          //     style: textTheme.bodySmall?.copyWith(color: Colors.black54),
          //   ),
          // ),
          // const SizedBox(height: 8),
        ],
      ),
    );
  }
}
