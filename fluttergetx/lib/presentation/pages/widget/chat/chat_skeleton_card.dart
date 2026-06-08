import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';

class ChatSkeletonCard extends StatefulWidget {
  const ChatSkeletonCard({super.key});

  @override
  State<ChatSkeletonCard> createState() => _ChatSkeletonCardState();
}

class _ChatSkeletonCardState extends State<ChatSkeletonCard>
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
    _anim = Tween<double>(begin: 0.25, end: 0.55)
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            _shimmer(50, 50, radius: 16),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmer(14, 160),
                  const SizedBox(height: 8),
                  _shimmer(12, double.infinity),
                ],
              ),
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
          color: AppColors.textGrey.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
