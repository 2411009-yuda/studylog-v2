import 'package:flutter_test/flutter_test.dart';

import 'fake_server.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('aplikasi terbuka dan menampilkan Beranda', (tester) async {
    await bukaApp(tester, FakeServer());

    expect(find.text('StudyLog'), findsWidgets);
    expect(find.text('Tentang Aplikasi'), findsOneWidget);
  });
}
