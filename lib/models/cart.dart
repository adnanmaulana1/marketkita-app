class CartItem {
  final int id;
  final int productId;
  final String nama;
  final String slug;
  final int harga;
  final String gambar;
  final int qty;
  final String varian;
  final int stok;
  final int subtotal;
  final int? tokoId;
  final String? tokoNama;

  CartItem({
    required this.id,
    required this.productId,
    required this.nama,
    required this.slug,
    required this.harga,
    required this.gambar,
    required this.qty,
    this.varian = '',
    required this.stok,
    required this.subtotal,
    this.tokoId,
    this.tokoNama,
  });

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        id: (j['id'] as num?)?.toInt() ?? 0,
        productId: (j['product_id'] as num?)?.toInt() ?? 0,
        nama: j['nama'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        harga: (j['harga'] as num?)?.toInt() ?? 0,
        gambar: j['gambar'] as String? ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 1,
        varian: j['varian'] as String? ?? '',
        stok: (j['stok'] as num?)?.toInt() ?? 0,
        subtotal: (j['subtotal'] as num?)?.toInt() ?? 0,
        tokoId: (j['toko']?['id'] as num?)?.toInt(),
        tokoNama: j['toko']?['nama'] as String?,
      );
}

class Cart {
  final List<CartItem> items;
  final int subtotal;
  final int count;

  Cart({required this.items, required this.subtotal, required this.count});

  factory Cart.fromJson(Map<String, dynamic> j) => Cart(
        items: (j['items'] as List?)?.map((e) => CartItem.fromJson(e)).toList() ?? [],
        subtotal: (j['subtotal'] as num?)?.toInt() ?? 0,
        count: (j['count'] as num?)?.toInt() ?? 0,
      );
}
