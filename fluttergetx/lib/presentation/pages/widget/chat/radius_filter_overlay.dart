import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/presentation/controllers/hospital_controller.dart';
import 'package:get/get.dart';

/// [RadiusFilterOverlay] adalah widget overlay untuk memfilter radius pencarian RSGM.
/// Menampilkan chip radius yang dapat dipilih pengguna secara intuitif.
class RadiusFilterOverlay extends StatelessWidget {
  final HospitalController controller;

  const RadiusFilterOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 16,
      left: 12,
      right: 12,
      child: _FilterCard(controller: controller),
    );
  }
}

class _FilterCard extends StatelessWidget {
  final HospitalController controller;

  const _FilterCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _FilterHeader(),
          const SizedBox(height: 10),
          _RadiusChipList(controller: controller),
        ],
      ),
    );
  }
}

class _FilterHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.radar_rounded,
            color: AppColors.primary,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'Filter Radius',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
        Obx(
          () => _HospitalCountBadge(
            count: Get.find<HospitalController>().hospitals.length,
          ),
        ),
      ],
    );
  }
}

class _HospitalCountBadge extends StatelessWidget {
  final int count;

  const _HospitalCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: Container(
        key: ValueKey(count),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: count > 0 ? AppColors.primary : AppColors.textGrey,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '$count RSGM',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _RadiusChipList extends StatelessWidget {
  final HospitalController controller;

  const _RadiusChipList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: controller.radiusOptions.map((radius) {
            final isSelected =
                (controller.selectedRadius.value - radius).abs() <
                0.001; // Using tolerance to avoid double precision issues when comparing radius values.
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _RadiusChip(
                radius: radius,
                isSelected: isSelected,
                onTap: () => controller.updateRadius(radius),
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}

class _RadiusChip extends StatelessWidget {
  final double radius;
  final bool isSelected;
  final VoidCallback onTap;

  const _RadiusChip({
    required this.radius,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.primary.withOpacity(0.2),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '${radius.toInt()} km',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.primary,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
