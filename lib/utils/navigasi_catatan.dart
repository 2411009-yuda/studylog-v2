import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../screens/catatan_form_screen.dart';
import '../viewmodels/mata_kuliah_view_model.dart';

/// Membuka form catatan baru. Mata kuliah terisi otomatis dari jadwal hari
/// ini (lihat cariJadwalUntukCatatan). Dipakai tombol +, tombol "Buat
/// Catatan" di Beranda, dan tombol "Tambah" di Daftar Catatan.
void bukaFormCatatanBaru(BuildContext context) {
  final jadwal = context.read<MataKuliahViewModel>().jadwalUntukCatatanBaru();
  Navigator.pushNamed(
    context,
    AppRoutes.form,
    arguments: CatatanFormArgs(jadwal: jadwal),
  );
}
