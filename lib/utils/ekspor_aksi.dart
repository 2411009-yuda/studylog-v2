import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ekspor_service.dart';

/// Menyalin [teks] ke clipboard lalu memberi tahu pengguna.
Future<void> salinTeks(
  BuildContext context,
  String teks, {
  required String pesan,
}) async {
  final service = context.read<EksporService>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    await service.salin(teks);
    messenger.showSnackBar(SnackBar(content: Text(pesan)));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Gagal menyalin: $e')));
  }
}

/// Membuka share sheet Android untuk [teks].
Future<void> bagikanTeks(
  BuildContext context,
  String teks, {
  String? subjek,
}) async {
  final service = context.read<EksporService>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    await service.bagikan(teks, subjek: subjek);
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Gagal membagikan: $e')));
  }
}
