import 'package:flutter/material.dart';

import 'contact_screen.dart';
import 'course_list_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Kerangka utama dengan bottom navigation.
///
/// IndexedStack menjaga setiap tab tetap hidup, sehingga posisi scroll dan
/// state tab tidak hilang saat berpindah tab. Layar yang ditumpuk dengan
/// Navigator.push (Daftar, Detail, Form) tampil di atas shell ini.
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
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Mata Kuliah',
            ),
            NavigationDestination(
              icon: Icon(Icons.contact_mail_outlined),
              selectedIcon: Icon(Icons.contact_mail),
              label: 'Kontak',
            ),
          ],
        ),
      ),
    );
  }
}
