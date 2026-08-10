import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

class HomeBannerData {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  const HomeBannerData({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });
}

/// Carousel banner home — kartu terang, dot indicator di dalam kartu.
class BannerCarousel extends StatefulWidget {
  final List<HomeBannerData> banners;
  final double height;
  const BannerCarousel({super.key, required this.banners, this.height = 160});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  int _index = 0;
  late final PageController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      final next = (_index + 1) % widget.banners.length;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    });
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
  }

  void _resume() {
    if (_timer != null) return;
    _startAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification) _pause();
              if (n is ScrollEndNotification) _resume();
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.banners.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _card(widget.banners[i]),
            ),
          ),
          Positioned(right: 20, bottom: 14, child: _dots()),
        ],
      ),
    );
  }

  Widget _card(HomeBannerData b) {
    return InkWell(
      onTap: b.onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF1F1F2), Color(0xFFE7E7E9)],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: AppColors.neutral900)),
                    const SizedBox(height: 6),
                    Text(b.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.neutral600)),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: const Text('Cek Sekarang',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.white)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.cardShadow,
                ),
                child: Icon(b.icon, size: 32, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.banners.length, (i) {
        final active = i == _index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(left: 4),
          width: active ? 14 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.neutral300,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
