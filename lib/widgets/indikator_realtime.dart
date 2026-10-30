import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/realtime_service.dart';

/// Ikon kecil di AppBar: apakah pembaruan real-time sedang aktif.
class IndikatorRealtime extends StatelessWidget {
  const IndikatorRealtime({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<RealtimeService>().status;

    final (IconData ikon, String pesan, double opasitas) = switch (status) {
      StatusRealtime.tersambung => (Icons.sensors, 'Real-time aktif', 1.0),
      StatusRealtime.menyambung => (
          Icons.sensors,
          'Menyambung real-time...',
          0.6
        ),
      StatusRealtime.terputus => (
          Icons.sensors_off,
          'Real-time terputus',
          0.6
        ),
    };

    return Tooltip(
      message: pesan,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Opacity(opacity: opasitas, child: Icon(ikon, size: 22)),
      ),
    );
  }
}
