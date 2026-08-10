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

  /// Melengkapi path relatif dari API (mis. "/static/products/x.jpg")
  /// menjadi URL absolut terhadap [baseUrl]. URL yang sudah punya skema
  /// (http/https) dikembalikan apa adanya.
  static String resolveImageUrl(String url) {
    if (url.isEmpty) return url;
    final u = Uri.tryParse(url);
    if (u == null || u.hasScheme) return url;
    final prefix = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return prefix + (url.startsWith('/') ? url.substring(1) : url);
  }
}
