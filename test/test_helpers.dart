import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Layar uji bawaan hanya 800x600, sehingga tombol di bagian bawah layar
/// berada di luar jangkauan tap. Layar yang lebih tinggi memuat semua konten.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Menekan satu tab pada bottom navigation (bukan teks lain dengan nama sama).
Future<void> tapTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  ));
  await tester.pumpAndSettle();
}
