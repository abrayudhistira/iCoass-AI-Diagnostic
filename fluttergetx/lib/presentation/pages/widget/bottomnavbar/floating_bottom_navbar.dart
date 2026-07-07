import 'package:flutter/material.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:fluttergetx/core/constants/colors.dart';

class FloatingNavItem {
  final IconData icon;
  final String label;
  const FloatingNavItem({required this.icon, required this.label});
}

// class FloatingBottomNavBar extends StatelessWidget {
//   final List<FloatingNavItem> items;
//   final int currentIndex;
//   final int floatingIndex; // -1 jika tidak ada item floating
//   final ValueChanged<int> onTap;
//   final double barHeight;
//   final double floatingSize;

//   const FloatingBottomNavBar({
//     super.key,
//     required this.items,
//     required this.currentIndex,
//     required this.onTap,
//     this.floatingIndex = -1,
//     this.barHeight = 64,
//     this.floatingSize = 66,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return BottomBar(
//       fit: StackFit.expand,
//       icon: (width, height) => _buildBarContent(width, height),
//       barColor: AppColors.primary,
//       width: MediaQuery.of(context).size.width * 0.9,
//       borderRadius: BorderRadius.circular(500),
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.decelerate,
//       showIcon: true,
//       iconHeight: floatingSize,
//       iconWidth: floatingSize,
//       reverse: false,
//       hideOnScroll: true,
//       scrollOpposite: false,
//       onBottomBarShown: null,
//       onBottomBarHidden: null,
//       child: const SizedBox.shrink(), // body dihandle di MainNavigationWrapper
//     );
//   }

//   Widget _buildBarContent(double width, double height) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceAround,
//       children: List.generate(items.length, (index) {
//         if (index == floatingIndex) {
//           return _FloatingCircleButton(
//             item: items[index],
//             isActive: currentIndex == floatingIndex,
//             onTap: () => onTap(index),
//             size: floatingSize,
//           );
//         }
//         return _NavIconItem(
//           item: items[index],
//           isActive: index == currentIndex,
//           onTap: () => onTap(index),
//         );
//       }),
//     );
//   }
// }