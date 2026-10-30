/// Alamat API StudyLog (Node.js + MySQL).
///
/// - Emulator Android : http://10.0.2.2:3000  (bawaan)
/// - HP via USB       : adb reverse tcp:3000 tcp:3000, lalu jalankan
///     flutter run --dart-define=API_BASE_URL=http://localhost:3000
/// - HP via Wi-Fi     : --dart-define=API_BASE_URL=http://IP-KOMPUTER:3000
class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const timeout = Duration(seconds: 8);

  /// Alamat WebSocket real-time (port yang sama dengan API).
  static Uri get wsUri => wsUriDari(baseUrl);
}

/// http://host:3000 -> ws://host:3000/ws ; https -> wss.
Uri wsUriDari(String baseUrl) {
  final uri = Uri.parse(baseUrl);
  return uri.replace(
    scheme: uri.scheme == 'https' ? 'wss' : 'ws',
    path: '/ws',
  );
}
