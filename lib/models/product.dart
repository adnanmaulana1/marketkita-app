class Category {
  final int id;
  final String nama;
  final String slug;
  final String ikon;

  Category({required this.id, required this.nama, required this.slug, this.ikon = ''});

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: (j['id'] as num?)?.toInt() ?? 0,
        nama: j['nama'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        ikon: j['ikon'] as String? ?? '',
      );
}

class TokoInfo {
  final int id;
  final String nama;
  final String slug;
  final String? alamat;
  final double? latitude;
  final double? longitude;

  TokoInfo({
    required this.id,
    required this.nama,
    required this.slug,
    this.alamat,
    this.latitude,
    this.longitude,
  });

  factory TokoInfo.fromJson(Map<String, dynamic>? j) {
    if (j == null) return TokoInfo(id: 0, nama: '', slug: '');
    return TokoInfo(
      id: (j['id'] as num?)?.toInt() ?? 0,
      nama: j['nama'] as String? ?? '',
      slug: j['slug'] as String? ?? '',
      alamat: j['alamat'] as String?,
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
    );
  }
}

class Product {
  final int id;
  final String nama;
  final String slug;
  final String deskripsi;
  final int harga;
  final int? hargaCoret;
  final int stok;
  final int beratGram;
  final String merek;
  final Map<String, dynamic> varian;
  final List<String> gambarUrl;
  final double rating;
  final int terjual;
  final String kategori;
  final String kategoriSlug;
  final TokoInfo toko;
  final bool isActive;

  Product({
    required this.id,
    required this.nama,
    required this.slug,
    this.deskripsi = '',
    required this.harga,
    this.hargaCoret,
    this.stok = 0,
    this.beratGram = 0,
    this.merek = '',
    this.varian = const {},
    this.gambarUrl = const [],
    this.rating = 0,
    this.terjual = 0,
    this.kategori = '',
    this.kategoriSlug = '',
    required this.toko,
    this.isActive = true,
  });

  bool get hasDiskon => hargaCoret != null && hargaCoret! > harga;

  int get diskonPersen => hasDiskon ? ((hargaCoret! - harga) * 100 ~/ hargaCoret!) : 0;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: (j['id'] as num?)?.toInt() ?? 0,
        nama: j['nama'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        deskripsi: j['deskripsi'] as String? ?? '',
        harga: (j['harga'] as num?)?.toInt() ?? 0,
        hargaCoret: (j['harga_coret'] as num?)?.toInt(),
        stok: (j['stok'] as num?)?.toInt() ?? 0,
        beratGram: (j['berat_gram'] as num?)?.toInt() ?? 0,
        merek: j['merek'] as String? ?? '',
        varian: Map<String, dynamic>.from(j['varian'] as Map? ?? {}),
        gambarUrl: (j['gambar_url'] as List?)?.map((e) => e.toString()).toList() ?? [],
        rating: (j['rating'] as num?)?.toDouble() ?? 0,
        terjual: (j['terjual'] as num?)?.toInt() ?? 0,
        kategori: j['kategori'] as String? ?? '',
        kategoriSlug: j['kategori_slug'] as String? ?? '',
        toko: TokoInfo.fromJson(j['toko'] as Map<String, dynamic>?),
        isActive: j['is_active'] as bool? ?? true,
      );
}
