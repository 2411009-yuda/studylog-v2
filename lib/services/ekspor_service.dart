import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// Aksi platform untuk ekspor teks. Dibuat sebagai antarmuka agar dapat
/// diganti tiruan pada pengujian (clipboard dan share sheet tidak ada di
/// lingkungan tes).
abstract class EksporService {
  Future<void> salin(String teks);
  Future<void> bagikan(String teks, {String? subjek});
}

class EksporServiceBawaan implements EksporService {
  const EksporServiceBawaan();

  @override
  Future<void> salin(String teks) => Clipboard.setData(ClipboardData(text: teks));

  @override
  Future<void> bagikan(String teks, {String? subjek}) async {
    await Share.share(teks, subject: subjek);
  }
}
