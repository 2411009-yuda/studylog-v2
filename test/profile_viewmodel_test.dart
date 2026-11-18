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

      vm.updateProfile(
        nama: '  Yuda P  ',
        nim: ' 2411010 ',
        programStudi: ' S1 Informatika ',
        status: ' Cuti ',
        semester: 6,
        email: ' yuda@mail.com ',
      );

      expect(vm.student.nama, 'Yuda P');
      expect(vm.student.nim, '2411010');
      expect(vm.student.programStudi, 'S1 Informatika');
      expect(vm.student.status, 'Cuti');
      expect(vm.student.semester, 6);
      expect(vm.student.email, 'yuda@mail.com');
      expect(notified, 1);
    });

    test('validateNim & validateStatus menolak kosong', () {
      final vm = ProfileViewModel();
      expect(vm.validateNim(' '), 'NIM wajib diisi');
      expect(vm.validateNim('2411009'), isNull);
      expect(vm.validateStatus(''), 'Status wajib diisi');
      expect(vm.validateStatus('Aktif'), isNull);
    });

    test('validateSemester menolak kosong, bukan angka, dan kurang dari 1',
        () {
      final vm = ProfileViewModel();
      expect(vm.validateSemester(''), 'Semester wajib diisi');
      expect(vm.validateSemester('abc'), isNotNull);
      expect(vm.validateSemester('0'), isNotNull);
      expect(vm.validateSemester('5'), isNull);
    });

    test("validateEmail wajib diisi dan wajib mengandung '@'", () {
      final vm = ProfileViewModel();
      expect(vm.validateEmail(''), 'Email wajib diisi');
      expect(vm.validateEmail('   '), 'Email wajib diisi');
      expect(vm.validateEmail('yudamail.com'), isNotNull);
      expect(vm.validateEmail('yuda@mail.com'), isNull);
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
