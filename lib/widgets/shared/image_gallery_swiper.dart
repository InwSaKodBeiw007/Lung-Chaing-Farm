// lib/widgets/shared/image_gallery_swiper.dart
import 'package:flutter/material.dart';
import 'package:lung_chaing_farm/services/api_service.dart'; // Import ApiService for baseUrl

class ImageGallerySwiper extends StatefulWidget {
  final List<String> imageUrls;
  final double height;

  const ImageGallerySwiper({
    super.key,
    required this.imageUrls,
    this.height = 200,
  });

  @override
  State<ImageGallerySwiper> createState() => _ImageGallerySwiperState();
}

class _ImageGallerySwiperState extends State<ImageGallerySwiper> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int? nextPage = _pageController.page?.round();
      if (nextPage != null && _currentPage != nextPage) {
        setState(() {
          _currentPage = nextPage;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Container(
        height: widget.height,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              final fullImageUrl = '${ApiService.baseUrl}/${widget.imageUrls[index].replaceAll('\\\\', '/')}' ;
              return Image.network(
                fullImageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.red)),
              );
            },
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.imageUrls.map((url) {
                  int index = widget.imageUrls.indexOf(url);
                  return Container(
                    width: 8.0,
                    height: 8.0,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
