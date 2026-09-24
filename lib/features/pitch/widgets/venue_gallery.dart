import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// صور الملعب بالتقليب + نقط العدّ. الضغط على صورة بيكبّرها.
class VenueGallery extends StatefulWidget {
  const VenueGallery({super.key, required this.photos});
  final List<String> photos;

  @override
  State<VenueGallery> createState() => _VenueGalleryState();
}

class _VenueGalleryState extends State<VenueGallery> {
  int _page = 0;

  void _zoom(String url) {
    showDialog(
      context: context,
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: InteractiveViewer(child: Center(child: Image.network(url))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.photos.isEmpty) {
      return Container(
        height: 200,
        color: AppColors.night2,
        child: const Icon(Icons.stadium_outlined, size: 64, color: AppColors.white),
      );
    }
    return SizedBox(
      height: 230,
      child: Stack(children: [
        PageView(
          onPageChanged: (i) => setState(() => _page = i),
          children: [
            for (final url in widget.photos)
              GestureDetector(
                onTap: () => _zoom(url),
                child: Image.network(url, fit: BoxFit.cover,
                    loadingBuilder: (_, child, p) =>
                        p == null ? child : Container(color: AppColors.night2),
                    errorBuilder: (_, __, ___) => Container(
                        color: AppColors.night2,
                        child: const Icon(Icons.broken_image_outlined, color: AppColors.white))),
              ),
          ],
        ),
        if (widget.photos.length > 1)
          Positioned(
            bottom: 8, left: 0, right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < widget.photos.length; i++)
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  color: i == _page ? AppColors.white : AppColors.white.withValues(alpha: 0.4),
                ),
            ]),
          ),
      ]),
    );
  }
}
