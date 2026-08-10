import 'package:flutter_test/flutter_test.dart';
import 'package:marketkita_app/models/cart.dart';
import 'package:marketkita_app/models/chat.dart';
import 'package:marketkita_app/models/order.dart';
import 'package:marketkita_app/models/product.dart';
import 'package:marketkita_app/models/user.dart';
import 'package:marketkita_app/models/voucher.dart';

void main() {
  group('Product', () {
    test('parse lengkap dengan toko & varian', () {
      final p = Product.fromJson({
        'id': 1,
        'nama': 'Beras Premium',
        'slug': 'beras-premium',
        'deskripsi': 'Beras 5kg',
        'harga': 65000,
        'harga_coret': 75000,
        'stok': 20,
        'berat_gram': 5000,
        'merek': 'Pandan',
        'varian': {'Ukuran': ['5kg', '10kg']},
        'gambar_url': ['https://cdn/1.jpg'],
        'rating': 4.5,
        'terjual': 12,
        'kategori': 'Sembako',
        'kategori_slug': 'sembako-bahan-pokok',
        'toko': {
          'id': 2,
          'nama': 'Toko A',
          'slug': 'toko-a',
          'alamat': 'Jl. Jenderal Sudirman',
          'latitude': -3.42,
          'longitude': 119.31,
        },
        'is_active': true,
      });

      expect(p.id, 1);
      expect(p.nama, 'Beras Premium');
      expect(p.harga, 65000);
      expect(p.hargaCoret, 75000);
      expect(p.rating, 4.5);
      expect(p.varian['Ukuran'], ['5kg', '10kg']);
      expect(p.gambarUrl, ['https://cdn/1.jpg']);
      expect(p.toko.nama, 'Toko A');
      expect(p.toko.slug, 'toko-a');
      expect(p.toko.latitude, -3.42);
      expect(p.hasDiskon, isTrue);
      expect(p.diskonPersen, ((75000 - 65000) * 100 ~/ 75000));
    });

    test('default bila field hilang', () {
      final p = Product.fromJson({'id': 1, 'nama': 'X', 'harga': 1000});
      expect(p.slug, '');
      expect(p.hargaCoret, isNull);
      expect(p.stok, 0);
      expect(p.varian, isEmpty);
      expect(p.gambarUrl, isEmpty);
      expect(p.toko.id, 0);
      expect(p.hasDiskon, isFalse);
      expect(p.diskonPersen, 0);
      expect(p.isActive, isTrue);
    });

    test('harga_coret lebih rendah berarti tidak diskon', () {
      final p = Product.fromJson({'id': 1, 'nama': 'X', 'harga': 1000, 'harga_coret': 900});
      expect(p.hasDiskon, isFalse);
    });
  });

  group('Order', () {
    test('parse lengkap dengan items & store', () {
      final o = Order.fromJson({
        'id': 5,
        'nomor': 'MK-123',
        'status': 'dikirim',
        'status_kurir': 'perjalanan',
        'subtotal': 50000,
        'ongkir': 10000,
        'diskon': 5000,
        'voucher_kode': 'HEMAT10',
        'total': 55000,
        'metode_pengiriman': 'Kurir Lokal (Ojek)',
        'metode_bayar': 'COD',
        'catatan': 'Cepat',
        'nama_penerima': 'Budi',
        'telepon': '0812',
        'alamat': 'Jl. A',
        'latitude': -3.42,
        'longitude': 119.3,
        'created_at': '2026-08-09T10:00:00',
        'items': [
          {'id': 1, 'product_id': 9, 'nama': 'Beras', 'harga': 50000, 'qty': 1, 'varian': ''},
        ],
        'store': {'id': 2, 'nama': 'Toko A', 'slug': 'toko-a', 'latitude': -3.4, 'longitude': 119.2},
      });

      expect(o.id, 5);
      expect(o.nomor, 'MK-123');
      expect(o.status, 'dikirim');
      expect(o.statusLabel, 'Dikirim');
      expect(o.statusKurir, 'perjalanan');
      expect(o.total, 55000);
      expect(o.items, hasLength(1));
      expect(o.items.first.nama, 'Beras');
      expect(o.storeId, 2);
      expect(o.storeNama, 'Toko A');
      expect(o.storeLatitude, -3.4);
      expect(o.latitude, -3.42);
    });

    test('store & items opsional', () {
      final o = Order.fromJson({'id': 1, 'nomor': 'MK-1', 'status': 'baru', 'subtotal': 0, 'ongkir': 0, 'diskon': 0, 'total': 0});
      expect(o.items, isEmpty);
      expect(o.storeId, isNull);
      expect(o.storeNama, isNull);
      expect(o.statusLabel, 'Baru');
    });

    test('statusLabel default ke nilai mentah', () {
      final o = Order.fromJson({'id': 1, 'nomor': 'MK-1', 'status': 'aneh', 'subtotal': 0, 'ongkir': 0, 'diskon': 0, 'total': 0});
      expect(o.statusLabel, 'aneh');
    });
  });

  group('Cart', () {
    test('parse dengan nested toko', () {
      final c = Cart.fromJson({
        'items': [
          {
            'id': 1,
            'product_id': 9,
            'nama': 'Beras',
            'slug': 'beras',
            'harga': 10000,
            'gambar': 'https://cdn/1.jpg',
            'qty': 2,
            'varian': '5kg',
            'stok': 10,
            'subtotal': 20000,
            'toko': {'id': 2, 'nama': 'Toko A'},
          },
        ],
        'subtotal': 20000,
        'count': 2,
      });

      expect(c.items, hasLength(1));
      expect(c.subtotal, 20000);
      expect(c.count, 2);
      expect(c.items.first.tokoId, 2);
      expect(c.items.first.tokoNama, 'Toko A');
      expect(c.items.first.subtotal, 20000);
    });

    test('items kosong default', () {
      final c = Cart.fromJson({'subtotal': 0, 'count': 0});
      expect(c.items, isEmpty);
      expect(c.subtotal, 0);
    });
  });

  group('User', () {
    test('parse lengkap', () {
      final u = User.fromJson({
        'id': 3,
        'nama': 'Budi',
        'email': 'budi@example.id',
        'telepon': '0812',
        'role': 'pembeli',
        'kendaraan': '',
        'saldo': 50000,
        'foto_profil': 'https://cdn/foto.jpg',
        'is_verified': true,
      });

      expect(u.id, 3);
      expect(u.nama, 'Budi');
      expect(u.email, 'budi@example.id');
      expect(u.role, 'pembeli');
      expect(u.saldo, 50000);
      expect(u.isVerified, isTrue);
    });

    test('default role pembeli', () {
      final u = User.fromJson({'id': 1, 'nama': 'X', 'email': 'x@y.id'});
      expect(u.role, 'pembeli');
      expect(u.saldo, 0);
      expect(u.isVerified, isFalse);
    });
  });

  group('Voucher & Transaksi', () {
    test('parse voucher', () {
      final v = Voucher.fromJson({
        'id': 1,
        'kode': 'HEMAT10',
        'nama': 'Hemat 10%',
        'deskripsi': 'Diskon',
        'tipe': 'persen',
        'nilai': 10,
        'min_belanja': 50000,
        'berlaku_sampai': '2026-12-31',
      });

      expect(v.kode, 'HEMAT10');
      expect(v.tipe, 'persen');
      expect(v.nilai, 10);
      expect(v.minBelanja, 50000);
      expect(v.berlakuSampai, '2026-12-31');
    });

    test('parse transaksi', () {
      final t = Transaksi.fromJson({
        'id': 1,
        'tipe': 'masuk',
        'jumlah': 50000,
        'keterangan': 'Top-up',
        'ref_type': 'topup',
        'created_at': '2026-08-09T10:00:00',
      });

      expect(t.tipe, 'masuk');
      expect(t.jumlah, 50000);
      expect(t.refType, 'topup');
    });
  });

  group('Chat', () {
    test('parse ChatUser', () {
      final u = ChatUser.fromJson({
        'id': 2,
        'nama': 'Toko A',
        'email': 'toko@example.id',
        'role': 'toko',
        'foto': '',
        'store_slug': 'toko-a',
      });
      expect(u.id, 2);
      expect(u.role, 'toko');
      expect(u.storeSlug, 'toko-a');
    });

    test('parse ChatMessage', () {
      final m = ChatMessage.fromJson({
        'id': 9,
        'conversation_id': 3,
        'sender_id': 1,
        'body': 'Halo',
        'is_read': false,
        'created_at': '2026-08-09T10:00:00',
      });
      expect(m.conversationId, 3);
      expect(m.senderId, 1);
      expect(m.body, 'Halo');
      expect(m.isRead, isFalse);
    });

    test('parse Conversation dengan peer & last', () {
      final c = Conversation.fromJson({
        'id': 3,
        'peer': {'id': 2, 'nama': 'Toko A', 'role': 'toko'},
        'last': {'body': 'Halo', 'created_at': '2026-08-09T10:00:00', 'sender_id': 1, 'is_read': true},
        'unread': 2,
        'updated_at': '2026-08-09T10:00:00',
      });
      expect(c.id, 3);
      expect(c.peer.nama, 'Toko A');
      expect(c.lastBody, 'Halo');
      expect(c.lastSenderId, 1);
      expect(c.lastIsRead, isTrue);
      expect(c.unread, 2);
    });
  });
}
