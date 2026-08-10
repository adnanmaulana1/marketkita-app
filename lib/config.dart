class AppConfig {
  // Base URL backend MarketKita.
  // Wajib HTTPS: semua trafik (API + WebSocket) melewati TLS.
  // WebSocket otomatis memakai wss:// selama scheme di sini https.
  static const String baseUrl = 'https://toko.adnanmaulana.my.id';
}
