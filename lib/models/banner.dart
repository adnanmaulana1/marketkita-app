class BannerItem {
  final int id;
  final String badge;
  final String judul;
  final String subtitle;
  final String gambarUrl;
  final String ctaText;
  final String ctaLink;

  BannerItem({
    required this.id,
    this.badge = '',
    this.judul = '',
    this.subtitle = '',
    this.gambarUrl = '',
    this.ctaText = '',
    this.ctaLink = '',
  });

  factory BannerItem.fromJson(Map<String, dynamic> j) => BannerItem(
        id: (j['id'] as num?)?.toInt() ?? 0,
        badge: j['badge'] as String? ?? '',
        judul: j['judul'] as String? ?? '',
        subtitle: j['subtitle'] as String? ?? '',
        gambarUrl: j['gambar_url'] as String? ?? '',
        ctaText: j['cta_text'] as String? ?? '',
        ctaLink: j['cta_link'] as String? ?? '',
      );
}
