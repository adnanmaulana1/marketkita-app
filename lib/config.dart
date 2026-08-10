class AppConfig {
  // Base URL backend MarketKita.
  // Wajib HTTPS: semua trafik (API + WebSocket) melewati TLS.
  // WebSocket otomatis memakai wss:// selama scheme di sini https.
  static const String baseUrl = 'https://toko.adnanmaulana.my.id';

  /// Ubah path relatif server (mis. /static/...) menjadi URL absolut.
  static String resolveUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) return '$baseUrl$path';
    return '$baseUrl/$path';
  }
}
