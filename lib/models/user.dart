class User {
  final int id;
  final String nama;
  final String email;
  final String telepon;
  final String role;
  final String kendaraan;
  final int saldo;
  final String fotoProfil;
  final bool isVerified;

  User({
    required this.id,
    required this.nama,
    required this.email,
    this.telepon = '',
    this.role = 'pembeli',
    this.kendaraan = '',
    this.saldo = 0,
    this.fotoProfil = '',
    this.isVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: (j['id'] as num?)?.toInt() ?? 0,
        nama: j['nama'] as String? ?? '',
        email: j['email'] as String? ?? '',
        telepon: j['telepon'] as String? ?? '',
        role: j['role'] as String? ?? 'pembeli',
        kendaraan: j['kendaraan'] as String? ?? '',
        saldo: (j['saldo'] as num?)?.toInt() ?? 0,
        fotoProfil: j['foto_profil'] as String? ?? '',
        isVerified: j['is_verified'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama': nama,
        'email': email,
        'telepon': telepon,
        'role': role,
        'kendaraan': kendaraan,
        'saldo': saldo,
        'foto_profil': fotoProfil,
        'is_verified': isVerified,
      };
}
