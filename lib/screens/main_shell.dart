import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../utils/navigasi_catatan.dart';
import 'contact_screen.dart';
import 'course_list_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Kerangka utama: bottom bar dengan tombol aksi + di tengah.
///
/// Empat tab (Beranda, Profil, Mata Kuliah, Kontak) disimpan dalam
/// IndexedStack agar state tab tidak hilang saat berpindah. Tombol + bukan
/// tab: ia membuka form catatan baru dengan mata kuliah terisi otomatis
/// dari jadwal. Layar yang ditumpuk dengan Navigator.push tampil di atas
/// shell ini.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = <Widget>[
    HomeScreen(),
    ProfileScreen(),
    CourseListScreen(),
    ContactScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Tombol kembali pada tab lain mengarah ke Beranda lebih dulu.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _tabs),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          tooltip: 'Catatan baru',
          shape: const CircleBorder(),
          backgroundColor: UmColors.red,
          foregroundColor: Colors.white,
          onPressed: () => bukaFormCatatanBaru(context),
          child: const Icon(Icons.add, size: 32),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          padding: EdgeInsets.zero,
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Beranda',
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              _NavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profil',
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              const SizedBox(width: 72), // ruang untuk tombol + di tengah
              _NavItem(
                icon: Icons.school_outlined,
                selectedIcon: Icons.school,
                label: 'Mata Kuliah',
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
              _NavItem(
                icon: Icons.contact_mail_outlined,
                selectedIcon: Icons.contact_mail,
                label: 'Kontak',
                selected: _index == 3,
                onTap: () => setState(() => _index = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final warna = selected ? UmColors.navy : Colors.black54;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                decoration: BoxDecoration(
                  color: selected ? UmColors.yellow : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(selected ? selectedIcon : icon,
                    size: 22, color: warna),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: warna,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
