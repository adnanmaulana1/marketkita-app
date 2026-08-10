class AlamatKirim {
  final int id;
  final String label;
  final String namaPenerima;
  final String telepon;
  final String alamat;
  final double? lat;
  final double? lng;

  const AlamatKirim({
    required this.id,
    this.label = 'Rumah',
    this.namaPenerima = '',
    this.telepon = '',
    this.alamat = '',
    this.lat,
    this.lng,
  });

  factory AlamatKirim.fromJson(Map<String, dynamic> j) => AlamatKirim(
        id: (j['id'] as num?)?.toInt() ?? 0,
        label: j['label'] as String? ?? 'Rumah',
        namaPenerima: j['nama_penerima'] as String? ?? '',
        telepon: j['telepon'] as String? ?? '',
        alamat: j['alamat'] as String? ?? '',
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'nama_penerima': namaPenerima,
        'telepon': telepon,
        'alamat': alamat,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  AlamatKirim copyWith({String? label, String? namaPenerima, String? telepon, String? alamat, double? lat, double? lng}) =>
      AlamatKirim(
        id: id,
        label: label ?? this.label,
        namaPenerima: namaPenerima ?? this.namaPenerima,
        telepon: telepon ?? this.telepon,
        alamat: alamat ?? this.alamat,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
      );
}
