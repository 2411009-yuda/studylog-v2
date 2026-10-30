import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../utils/sinkron_aksi.dart';
import '../viewmodels/catatan_view_model.dart';

/// Memicu sinkronisasi otomatis: saat aplikasi kembali dari background, dan
/// berkala selama masih ada perubahan tertunda atau server sedang tak
/// terjangkau. (Penulisan data sendiri juga memicu sinkronisasi langsung.)
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final interval = widget.interval;
    if (interval != null) {
      _timer = Timer.periodic(interval, (_) => _berkala());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(sinkronSemua(context));
    }
  }

  void _berkala() {
    if (!mounted) return;
    final vm = context.read<CatatanViewModel>();
    if (vm.tertunda > 0 || vm.status == StatusSinkron.offline) {
      unawaited(sinkronSemua(context));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
