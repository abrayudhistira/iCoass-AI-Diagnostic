import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/colors.dart';

class FeatureItem {
  final String title;
  final IconData icon;
  final String route;
  const FeatureItem(this.title, this.icon, this.route);
}

const List<FeatureItem> _features = [
  FeatureItem(
    'Riwayat\nDiagnosa',
    Icons.medical_information_rounded,
    '/diagnosis-history',
  ),
  FeatureItem('Lokasi\nRSGM', Icons.location_on_rounded, '/patient-hospital'),
  FeatureItem('Artikel\nBerita', Icons.article_rounded, '/article-list'),
  FeatureItem(
    'Layanan\nPerawatan',
    Icons.medical_services_rounded,
    '/perawatan',
  ),
];

class FeaturesCarousel extends StatefulWidget {
  const FeaturesCarousel({super.key});

  @override
  State<FeaturesCarousel> createState() => _FeaturesCarouselState();
}

class _FeaturesCarouselState extends State<FeaturesCarousel> {
  static const int _perPage = 3;
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  int get _pageCount => (_features.length / _perPage).ceil();

  List<FeatureItem> _itemsForPage(int page) {
    final start = page * _perPage;
    final end = (start + _perPage).clamp(0, _features.length);
    return _features.sublist(start, end);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 90,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pageCount,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, page) {
                final items = _itemsForPage(page);
                return Row(
                  children: items
                      .map(
                        (item) => Expanded(child: _FeatureButton(item: item)),
                      )
                      .toList(),
                );
              },
            ),
          ),
          if (_pageCount > 1) ...[
            const SizedBox(height: 12),
            _DotsIndicator(pageCount: _pageCount, currentPage: _currentPage),
          ],
        ],
      ),
    );
  }
}

/// Dot indicator dengan efek "worm" — dot aktif melebar jadi pil.
class _DotsIndicator extends StatelessWidget {
  final int pageCount;
  final int currentPage;

  const _DotsIndicator({required this.pageCount, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          height: 7,
          width: isActive ? 20 : 7, // dot aktif melebar jadi pil
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.secondary,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final FeatureItem item;
  const _FeatureButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Get.toNamed(item.route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, size: 22, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
