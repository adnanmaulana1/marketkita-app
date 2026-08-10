import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../../config.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

/// Galeri gambar produk: PageView + indikator dots + badge diskon/counter,
/// tap gambar untuk membuka fullscreen dengan pinch-zoom (photo_view).
class ProductGallery extends StatefulWidget {
  final List<String> images;
  final int? diskonPersen;
  final int heroTag;
  const ProductGallery({
    super.key,
    required this.images,
    this.diskonPersen,
    required this.heroTag,
  });

  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  final _controller = PageController();
  int _current = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFullscreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => _GalleryViewer(
          images: widget.images,
          initialIndex: _current,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final hasImage = images.isNotEmpty;
    return Container(
      height: 360,
      color: AppColors.neutral100,
      child: hasImage
          ? Stack(
              children: [
                GestureDetector(
                  onTap: _openFullscreen,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _current = i),
                    itemBuilder: (_, i) => _image(i, hero: i == 0),
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < images.length; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _current ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _current ? AppColors.primary : AppColors.neutral300,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (widget.diskonPersen != null && widget.diskonPersen! > 0)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '-${widget.diskonPersen}%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${_current + 1}/${images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    child: IconButton(
                      tooltip: 'Perbesar',
                      icon: const Icon(Icons.fullscreen, size: 20, color: Colors.white),
                      onPressed: _openFullscreen,
                    ),
                  ),
                ),
              ],
            )
          : _placeholder(),
    );
  }

  Widget _image(int i, {required bool hero}) {
    final url = widget.images[i];
    Widget img = Image.network(
      AppConfig.resolveImageUrl(url),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: AppColors.neutral200,
        child: const Icon(Icons.image, size: 64, color: AppColors.neutral400),
      ),
    );
    if (hero) {
      img = Hero(
        tag: 'pdp-${widget.heroTag}',
        transitionOnUserGestures: true,
        child: img,
      );
    }
    return SizedBox(height: 360, child: img);
  }

  Widget _placeholder() {
    return SizedBox(
      height: 360,
      child: Container(
        color: AppColors.neutral200,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, size: 64, color: AppColors.neutral400),
              const SizedBox(height: 8),
              Text(
                'Gambar tidak tersedia',
                style: TextStyle(fontSize: 13, color: AppColors.neutral600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryViewer extends StatelessWidget {
  final List<String> images;
  final int initialIndex;
  const _GalleryViewer({required this.images, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${initialIndex + 1}/${images.length}', style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
      body: PhotoViewGallery.builder(
        itemCount: images.length,
        pageController: PageController(initialPage: initialIndex),
        onPageChanged: (i) {},
        builder: (_, i) => PhotoViewGalleryPageOptions(
          imageProvider: NetworkImage(AppConfig.resolveImageUrl(images[i])),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
          heroAttributes: i == 0 ? PhotoViewHeroAttributes(tag: 'pdp-gallery') : null,
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
      ),
    );
  }
}
