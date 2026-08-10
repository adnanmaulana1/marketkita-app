import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../utils/format.dart';
import 'pembeli/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _confirmRemove(BuildContext context, AppState app, int itemId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus item'),
        content: const Text('Hapus item ini dari keranjang?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await app.removeCart(itemId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final cart = app.cart;

    return Scaffold(
      appBar: AppBar(title: const Text('Keranjang')),
      body: cart == null || cart.items.isEmpty
          ? const _EmptyCart()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final item = cart.items[i];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: item.gambar.isEmpty
                              ? Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey))
                              : Image.network(item.gambar, fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                      color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.nama, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            if (item.varian.isNotEmpty) Text(item.varian, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            if (item.tokoNama != null) Text(item.tokoNama!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            const SizedBox(height: 6),
                            Text(rupiah(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove, size: 15),
                                        onPressed: () async {
                                          if (item.qty > 1) {
                                            await app.updateCart(item.id, item.qty - 1);
                                          }
                                        },
                                      ),
                                      Text('${item.qty}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 15),
                                        onPressed: () async {
                                          if (item.qty < item.stok) {
                                            await app.updateCart(item.id, item.qty + 1);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: () => _confirmRemove(context, app, item.id),
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                  label: const Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      bottomNavigationBar: cart == null || cart.items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Subtotal', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        Text(rupiah(cart.subtotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF171717),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Keranjang kosong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Temukan produk favorit dari UMKM lokal', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF171717), foregroundColor: Colors.white),
            child: const Text('Mulai Belanja'),
          ),
        ],
      ),
    );
  }
}
