# MarketKita App

Aplikasi mobile MarketKita (Flutter) — pembeli, toko, dan kurir.

## Persyaratan

- Flutter 3.44+ (stable)
- Backend MarketKita harus dapat diakses via HTTPS
  (base URL ada di `lib/config.dart`, saat ini `https://toko.adnanmaulana.my.id`).

## Menjalankan

```bash
flutter pub get
flutter run
```

## Konfigurasi & Keamanan

- Semua trafik API **dan WebSocket** memakai TLS (`https://` / `wss://`).
  Jangan kembalikan `AppConfig.baseUrl` ke `http://`.
- Token JWT disimpan di **Android Keystore / iOS Keychain**
  (`flutter_secure_storage`), bukan SharedPreferences.
  Migrasi token lama dari SharedPreferences dilakukan otomatis sekali jalan.
- `AndroidManifest.xml`: `android:usesCleartextTraffic="false"` dan
  `android:allowBackup="false"` (mencegah ekstraksi data lewat `adb backup`).

## Menandatangani APK Produksi

Saat ini `android/app/build.gradle.kts` masih menandatangani build `release`
dengan **debug key** (hanya untuk memudahkan `flutter run --release`).
Jangan upload APK ini ke Play Store.

Untuk produksi:

1. Buat keystore (rahasia, simpan di tempat aman dan jangan di-commit):
   ```bash
   keytool -genkey -v -keystore ~/keys/marketkita.jks -alias marketkita \
     -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Buat file `android/key.properties` (jangan di-commit, sudah masuk `.gitignore`):
   ```properties
   storePassword=<password-store>
   keyPassword=<password-key>
   keyAlias=marketkita
   storeFile=/absolute/path/ke/marketkita.jks
   ```

3. Di `android/app/build.gradle.kts`, tambahkan blok signing di `android {}`:
   ```kotlin
   import java.util.Properties
   import java.io.FileInputStream

   // di dalam blok `android { ... }` setelah `defaultConfig`:
   signingConfigs {
       create("release") {
           val props = Properties().apply {
               val f = rootProject.file("key.properties")
               if (f.exists()) load(FileInputStream(f))
           }
           storeFile = props.getProperty("storeFile")?.let { file(it) }
           storePassword = props.getProperty("storePassword")
           keyAlias = props.getProperty("keyAlias")
           keyPassword = props.getProperty("keyPassword")
       }
   }
   ```
   lalu ubah `buildTypes.release` menjadi:
   ```kotlin
   buildTypes {
       release {
           signingConfig = signingConfigs.getByName("release")
           isMinifyEnabled = true
           isShrinkResources = true
       }
   }
   ```

4. Build: `flutter build apk --release`.

## Pengujian

```bash
flutter test
```

Unit test mencakup parsing model (`test/models_test.dart`) dan util format
(`test/format_test.dart`).
