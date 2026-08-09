class Voucher {
  final int id;
  final String kode;
  final String nama;
  final String deskripsi;
  final String tipe;
  final int nilai;
  final int minBelanja;
  final String? berlakuSampai;

  Voucher({
    required this.id,
    required this.kode,
    required this.nama,
    this.deskripsi = '',
    required this.tipe,
    required this.nilai,
    this.minBelanja = 0,
    this.berlakuSampai,
  });

  factory Voucher.fromJson(Map<String, dynamic> j) => Voucher(
        id: (j['id'] as num?)?.toInt() ?? 0,
        kode: j['kode'] as String? ?? '',
        nama: j['nama'] as String? ?? '',
        deskripsi: j['deskripsi'] as String? ?? '',
        tipe: j['tipe'] as String? ?? 'nominal',
        nilai: (j['nilai'] as num?)?.toInt() ?? 0,
        minBelanja: (j['min_belanja'] as num?)?.toInt() ?? 0,
        berlakuSampai: j['berlaku_sampai'] as String?,
      );
}

class Transaksi {
  final int id;
  final String tipe;
  final int jumlah;
  final String keterangan;
  final String refType;
  final String? createdAt;

  Transaksi({
    required this.id,
    required this.tipe,
    required this.jumlah,
    required this.keterangan,
    this.refType = '',
    this.createdAt,
  });

  factory Transaksi.fromJson(Map<String, dynamic> j) => Transaksi(
        id: (j['id'] as num?)?.toInt() ?? 0,
        tipe: j['tipe'] as String? ?? '',
        jumlah: (j['jumlah'] as num?)?.toInt() ?? 0,
        keterangan: j['keterangan'] as String? ?? '',
        refType: j['ref_type'] as String? ?? '',
        createdAt: j['created_at'] as String?,
      );
}
