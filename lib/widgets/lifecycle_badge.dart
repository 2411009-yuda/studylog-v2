import 'package:flutter/material.dart';

import '../app/theme.dart';
import 'um_widgets.dart';

/// Memantau lifecycle aplikasi (resumed, inactive, paused, ...) dan orientasi.
///
/// Cara uji: tekan tombol Home / pindah aplikasi lalu kembali, atau putar layar.
/// Riwayat transisi akan bertambah, sedangkan data profil di ViewModel tetap.
class LifecycleBadge extends StatefulWidget {
  const LifecycleBadge({super.key});

  @override
  State<LifecycleBadge> createState() => _LifecycleBadgeState();
}

class _LifecycleBadgeState extends State<LifecycleBadge>
    with WidgetsBindingObserver {
  AppLifecycleState _state = AppLifecycleState.resumed;
  final List<String> _history = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final current = WidgetsBinding.instance.lifecycleState;
    if (current != null) _state = current;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[Lifecycle] $state');
    setState(() {
      _state = state;
      _history.insert(0, '${_clock()}  ${state.name}');
      if (_history.length > 5) _history.removeLast();
    });
  }

  String _clock() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.orientationOf(context);
    final textTheme = Theme.of(context).textTheme;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync_alt, color: UmColors.blue),
              const SizedBox(width: 8),
              Text(
                'Pemantau Lifecycle',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: UmColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Status aplikasi: ${_state.name}'),
          Text('Orientasi: ${orientation.name}'),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Riwayat terakhir',
                style: textTheme.labelMedium?.copyWith(color: Colors.black54)),
            for (final item in _history)
              Text(item, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
