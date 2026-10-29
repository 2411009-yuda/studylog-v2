import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Garis merah-kuning di bawah AppBar, mengingatkan pada lambang Universitas Mulia.
class UmStripe extends StatelessWidget implements PreferredSizeWidget {
  const UmStripe({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(4);

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 4,
      child: Row(
        children: [
          Expanded(child: ColoredBox(color: UmColors.red)),
          Expanded(child: ColoredBox(color: UmColors.yellow)),
        ],
      ),
    );
  }
}

AppBar umAppBar(String title) {
  return AppBar(title: Text(title), bottom: const UmStripe());
}

/// Kartu putih dengan sudut membulat yang dipakai di semua layar.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E7F0)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Satu baris "label: nilai" pada kartu profil.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: UmColors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: textTheme.labelMedium
                        ?.copyWith(color: Colors.black54)),
                const SizedBox(height: 2),
                Text(value, style: textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
