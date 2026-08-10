import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../screens/pembeli/product_detail_screen.dart';
import '../state/app_state.dart';
import '../utils/format.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  /// Tinggi tetap kartu agar semua grid memakai ukuran seragam (tidak miring).
  static const double cardHeight = 304;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: product.id, initialProduct: product)),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                  if (product.gambarUrl.isEmpty)
                    Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey, size: 40))
                  else
                    Hero(
                      tag: 'product-image-${product.id}',
                      child: CachedNetworkImage(
                        imageUrl: product.gambarUrl.first,
                        fit: BoxFit.cover,
                        memCacheWidth: 400,
                        placeholder: (_, _) => Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey, size: 40)),
                        errorWidget: (_, _, _) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, color: Colors.grey, size: 40),
                        ),
                      ),
                    ),
                  if (product.hasDiskon)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('-${product.diskonPersen}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    // Selector: rebuild hanya saat status favorit produk ini
                    // berubah, bukan pada setiap notifyListeners.
                    child: Selector<AppState, bool>(
                      selector: (_, app) => app.favoritIds.contains(product.id),
                      builder: (context, isFav, _) => InkWell(
                        onTap: () async {
                          final app = context.read<AppState>();
                          if (!app.isLoggedIn) {
                            Navigator.pushNamed(context, '/login');
                            return;
                          }
                          final fav = await app.toggleFavorite(product.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(fav ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: isFav ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Text(rupiah(product.harga), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                  if (product.hasDiskon) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(4)),
                          child: Text('${product.diskonPersen}%', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(rupiah(product.hargaCoret!),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Colors.grey[400], decoration: TextDecoration.lineThrough)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  if (product.toko.nama.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.verified, size: 13, color: Colors.black),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(product.toko.nama,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  if (product.toko.alamat != null && product.toko.alamat!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(product.toko.alamat!,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 13, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text('${product.rating}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('(${product.terjual} terjual)',
                            maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
