import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/routes.dart';
import '../viewmodels/pengingat_view_model.dart';

/// Tombol lonceng di AppBar: badge menunjukkan jumlah hal yang terlewat,
/// ketukan membuka layar Notifikasi.
class BelNotifikasi extends StatelessWidget {
  const BelNotifikasi({super.key});

  @override
  Widget build(BuildContext context) {
    final jumlah = context.watch<PengingatViewModel>().daftar.length;
    return IconButton(
      tooltip: 'Notifikasi',
      onPressed: () => Navigator.pushNamed(context, AppRoutes.notifikasi),
      icon: Badge(
        isLabelVisible: jumlah > 0,
        label: Text('$jumlah'),
        child: Icon(jumlah > 0
            ? Icons.notifications_active
            : Icons.notifications_none),
      ),
    );
  }
}
