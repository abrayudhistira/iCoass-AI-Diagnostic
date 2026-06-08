import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';

/// Skeleton loading card untuk UserManagementPage.
class UserSkeletonCard extends StatefulWidget {
  const UserSkeletonCard({super.key});

  @override
  State<UserSkeletonCard> createState() => _UserSkeletonCardState();
}

class _UserSkeletonCardState extends State<UserSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.2, end: 0.5)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _shimmer(48, 48, radius: 14),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _shimmer(14, double.infinity)),
                      const SizedBox(width: 8),
                      _shimmer(18, 60, radius: 99),
                    ],
                  ),
                  const SizedBox(height: 7),
                  _shimmer(11, 100),
                  const SizedBox(height: 5),
                  _shimmer(11, 160),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                _shimmer(32, 32, radius: 10),
                const SizedBox(height: 6),
                _shimmer(32, 32, radius: 10),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmer(double h, double w, {double radius = 8}) => Container(
        height: h,
        width: w,
        decoration: BoxDecoration(
          color: AppColors.textGrey.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
