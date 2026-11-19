import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../viewmodels/catatan_view_model.dart';
import '../viewmodels/mata_kuliah_view_model.dart';
import '../viewmodels/penilaian_view_model.dart';

/// Menyinkronkan catatan dan penilaian dosen, dan memuat ulang mata kuliah jika sebelumnya
/// gagal/tampil dari cache (server baru terjangkau lagi).
Future<void> sinkronSemua(BuildContext context) {
  final catatan = context.read<CatatanViewModel>();
  final penilaian = context.read<PenilaianViewModel>();
  final mk = context.read<MataKuliahViewModel>();
  return Future.wait([
    catatan.sinkronkan(),
    penilaian.sinkronkan(),
    if (mk.dariCache || mk.error != null) mk.muat(),
  ]);
}
