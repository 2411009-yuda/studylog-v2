import 'package:flutter_test/flutter_test.dart';
import 'package:profil_mahasiswa/viewmodels/profile_viewmodel.dart';

void main() {
  group('ProfileViewModel', () {
    test('state awal berisi data Yuda Pratama', () {
      final vm = ProfileViewModel();
      expect(vm.student.nama, 'Yuda Pratama');
      expect(vm.student.nim, '2411009');
      expect(vm.student.programStudi, 'S1 Informatika');
      expect(vm.student.semester, 5);
      expect(vm.hasCustomPhoto, isFalse);
    });

    test('validateNama menolak kosong dan terlalu pendek', () {
      final vm = ProfileViewModel();
      expect(vm.validateNama(''), isNotNull);
      expect(vm.validateNama('   '), isNotNull);
      expect(vm.validateNama('Yu'), isNotNull);
      expect(vm.validateNama('Yuda'), isNull);
    });

    test('validateProdi menolak kosong', () {
      final vm = ProfileViewModel();
      expect(vm.validateProdi(''), isNotNull);
      expect(vm.validateProdi('S1 Informatika'), isNull);
    });

    test('updateProfile mengubah state, merapikan spasi, dan memberi notifikasi',
        () {
      final vm = ProfileViewModel();
      var notified = 0;
      vm.addListener(() => notified++);

      vm.updateProfile(nama: '  Yuda P  ', programStudi: ' S1 Informatika ');

      expect(vm.student.nama, 'Yuda P');
      expect(vm.student.programStudi, 'S1 Informatika');
      expect(vm.student.nim, '2411009'); // field lain tidak berubah
      expect(notified, 1);
    });

    test('courseById mengembalikan mata kuliah yang tepat atau null', () {
      final vm = ProfileViewModel();
      expect(vm.courseById('111000')?.nama, 'Pemrograman Aplikasi Bergerak');
      expect(vm.courseById('tidak-ada'), isNull);
    });

    test('kurikulum semester 5: 8 mata kuliah, 23 SKS, tanpa Robotika', () {
      final vm = ProfileViewModel();
      expect(vm.courses.length, 8);
      expect(vm.totalSks, 23);
      expect(vm.courses.any((c) => c.nama == 'Robotika'), isFalse);
    });

    test('resetPhoto memberi notifikasi', () {
      final vm = ProfileViewModel();
      var notified = 0;
      vm.addListener(() => notified++);
      vm.resetPhoto();
      expect(notified, 1);
      expect(vm.hasCustomPhoto, isFalse);
    });
  });
}
