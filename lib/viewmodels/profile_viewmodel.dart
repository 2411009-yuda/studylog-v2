import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/course.dart';
import '../models/student.dart';
import 'course_data.dart';

enum PhotoResult { changed, cancelled, failed }

/// State holder untuk seluruh layar aplikasi.
///
/// Layar (Beranda, Profil, Detail, Kontak) hanya MENAMPILKAN state dari sini
/// dan mengirim event (mis. [updateProfile]). Logika & validasi ada di sini,
/// sehingga data tetap ada saat pindah layar maupun saat layar dirotasi.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({ImagePicker? picker}) : _injectedPicker = picker;

  final ImagePicker? _injectedPicker;
  ImagePicker get _picker => _injectedPicker ?? ImagePicker();

  /// Foto pilihan pengguna. null = pakai foto bawaan dari aset.
  Uint8List? _photoBytes;
  Uint8List? get photoBytes => _photoBytes;
  bool get hasCustomPhoto => _photoBytes != null;

  Student _student = const Student(
    nama: 'Yuda Pratama',
    nim: '2411009',
    programStudi: 'S1 Informatika',
    status: 'Aktif',
    semester: 5,
    email: '2411009@students.universitasmulia.ac.id',
    portfolioUrl: 'https://yuda-pratama.web.id/',
    githubUrl: 'https://github.com/2411009-yuda',
  );

  Student get student => _student;

  List<Course> get courses => semesterCourses;

  int get totalSks => semesterCourses.fold(0, (sum, c) => sum + c.sks);

  Course? courseById(String kode) {
    for (final course in semesterCourses) {
      if (course.kode == kode) return course;
    }
    return null;
  }

  // ---- Event dari UI ----

  void updateProfile({required String nama, required String programStudi}) {
    _student = _student.copyWith(
      nama: nama.trim(),
      programStudi: programStudi.trim(),
    );
    notifyListeners();
  }

  Future<PhotoResult> changePhoto(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (file == null) return PhotoResult.cancelled;
      _photoBytes = await file.readAsBytes();
      notifyListeners();
      return PhotoResult.changed;
    } catch (_) {
      return PhotoResult.failed;
    }
  }

  void resetPhoto() {
    _photoBytes = null;
    notifyListeners();
  }

  // ---- Validasi (dipakai form Edit Profil) ----

  String? validateNama(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Nama wajib diisi';
    if (text.length < 3) return 'Nama minimal 3 karakter';
    return null;
  }

  String? validateProdi(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Program studi wajib diisi';
    return null;
  }
}
