import 'package:url_launcher/url_launcher.dart';

/// Membuka [uri] di aplikasi eksternal. Mengembalikan false jika gagal.
Future<bool> openExternal(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
