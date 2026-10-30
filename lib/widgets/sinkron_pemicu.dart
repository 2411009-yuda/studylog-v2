import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/realtime_service.dart';
import '../utils/sinkron_aksi.dart';
import '../viewmodels/catatan_view_model.dart';

/// Mengatur kapan data ditarik/dikirim:
/// - real-time: kabar dari server (WebSocket) memicu sinkronisasi, begitu juga
///   saat tersambung / sambung ulang;
/// - saat aplikasi kembali dari background (koneksi real-time disambung lagi);
/// - berkala sebagai CADANGAN: selama masih ada perubahan tertunda, server tak
///   terjangkau, atau real-time terputus (polling).
/// Penulisan data sendiri juga memicu sinkronisasi langsung (CatatanViewModel).
class SinkronPemicu extends StatefulWidget {
  const SinkronPemicu({super.key, required this.child, this.interval});

  final Widget child;

  /// Null = tanpa pengatur waktu berkala.
  final Duration? interval;

  @override
  State<SinkronPemicu> createState() => _SinkronPemicuState();
}

class _SinkronPemicuState extends State<SinkronPemicu>
    with WidgetsBindingObserver {
  Timer? _timer;
  RealtimeService? _realtime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final interval = widget.interval;
    if (interval != null) {
      _timer = Timer.periodic(interval, (_) => _berkala());
    }

    final realtime = context.read<RealtimeService>();
    _realtime = realtime
      ..onPerubahan = _tarik
      ..onTersambung = _tarik;
    // Setelah frame pertama, agar perubahan status tidak terjadi saat build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) realtime.mulai();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _realtime
      ?..onPerubahan = null
      ..onTersambung = null;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.paused) {
      // Android mematikan soket di background; lepas dengan rapi.
      unawaited(_realtime?.berhenti());
    } else if (state == AppLifecycleState.resumed) {
      _realtime?.mulai();
      unawaited(sinkronSemua(context));
    }
  }

  void _tarik() {
    if (!mounted) return;
    unawaited(sinkronSemua(context));
  }

  void _berkala() {
    if (!mounted) return;
    final vm = context.read<CatatanViewModel>();
    final realtime = _realtime;
    final realtimeBermasalah =
        realtime != null && realtime.aktif && !realtime.tersambung;
    if (vm.tertunda > 0 ||
        vm.status == StatusSinkron.offline ||
        realtimeBermasalah) {
      unawaited(sinkronSemua(context));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
