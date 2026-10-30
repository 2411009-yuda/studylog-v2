import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/utils/uuid.dart';

void main() {
  final pola = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

  test('buatUuidV4 menghasilkan UUID versi 4 yang valid', () {
    for (var i = 0; i < 50; i++) {
      expect(buatUuidV4(), matches(pola));
    }
  });

  test('buatUuidV4 unik', () {
    final set = {for (var i = 0; i < 500; i++) buatUuidV4()};
    expect(set, hasLength(500));
  });

  test('buatUuidV4 deterministik untuk Random yang sama', () {
    expect(buatUuidV4(Random(7)), buatUuidV4(Random(7)));
  });
}
