import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/presentation/pages/article/article_list_page.dart';
import 'package:fluttergetx/presentation/pages/chat/patient/chat_list_page.dart';
import 'package:fluttergetx/presentation/pages/diagnosis/diagnosis_history_page.dart';
import 'package:fluttergetx/presentation/pages/home/admin_home_page.dart';
import 'package:fluttergetx/presentation/pages/home/home_page.dart';
import 'package:fluttergetx/presentation/pages/profile/profile_page.dart';
import 'package:get/get.dart';
import 'package:fluttergetx/presentation/controllers/auth_controller.dart';
import 'package:fluttergetx/presentation/pages/widget/bottomnavbar/floating_bottom_navbar.dart';

class MainNavigationWrapper extends StatefulWidget {
  final int initialIndex;
  const MainNavigationWrapper({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  late int _currentIndex;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _determineRole();
  }

  Future<void> _determineRole() async {
    try {
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        final role = auth.currentUser.value?.role;
        if (role != null && role.toString().toLowerCase() == 'admin') {
          setState(() => _isAdmin = true);
          return;
        }
      }
      const storage = FlutterSecureStorage();
      final storedRole = await storage.read(key: 'role') ?? '';
      setState(() => _isAdmin = storedRole.toLowerCase() == 'admin');
    } catch (_) {}
  }

  List<Widget> _buildScreens() {
    if (_isAdmin) {
      return const [AdminHomePage(), ArticleListPage(), ProfilePage()];
    }
    return const [
      HomePage(),
      PatientChatListPage(),
      DiagnosisHistoryPage(),
      ArticleListPage(),
      ProfilePage(),
    ];
  }

  List<FloatingNavItem> _navItems() {
    if (_isAdmin) {
      return const [
        FloatingNavItem(icon: Icons.admin_panel_settings, label: "Admin"),
        FloatingNavItem(icon: Icons.article, label: "Artikel"),
        FloatingNavItem(icon: Icons.person_sharp, label: "Profil"),
      ];
    }
    return const [
      FloatingNavItem(icon: Icons.home_filled, label: "Home"),
      FloatingNavItem(icon: Icons.chat, label: "Chat"),
      FloatingNavItem(
        icon: Icons.history_rounded,
        label: "Diagnosis",
      ), // FAB
      FloatingNavItem(icon: Icons.newspaper_rounded, label: "Riwayat"),
      FloatingNavItem(icon: Icons.person_sharp, label: "Profil"),
    ];
  }

  int get _floatingIndex => _isAdmin ? -1 : 2;

  @override
  Widget build(BuildContext context) {
    final screens = _buildScreens();
    final navItems = _navItems();
    final floatingIdx = _floatingIndex;

    // child = floating bar widget
    // body  = konten scrollable (IndexedStack)
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BottomBar(
        layout: BottomBarLayout(
          width: MediaQuery.of(context).size.width - 32,
          borderRadius: BorderRadius.circular(500),
          offset: 12,
          fit: StackFit.expand,
          clip: Clip.none,
        ),
        motion: const BottomBarMotion.cupertino(
          preset: BottomBarCupertinoMotion.snappy,
          duration: Duration(milliseconds: 400),
          slideStart: Offset(0, 3),
        ),
        scrollBehavior: const BottomBarScrollBehavior(hideOnScroll: true),
        // theme: BottomBarThemeData(
        //   barDecoration: BoxDecoration(
        //     color: AppColors.primary,
        //     borderRadius: BorderRadius.circular(500),
        //   ),
        // ),
        theme: BottomBarThemeData(
          barDecoration: BoxDecoration(
            // Gradient biru gelap → biru terang biar tidak flat
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0062CC), // biru gelap
                AppColors.primary, // biru utama
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(500),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
        showIcon: false, // tidak pakai back-to-top icon
        body: IndexedStack(index: _currentIndex, children: screens),
        // child = isi bar yang floating
        child: floatingIdx >= 0
            ? Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Row semua item kecuali floatingIndex
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(navItems.length, (index) {
                        if (index == floatingIdx) {
                          return const SizedBox(width: 66);
                        }
                        return _NavIconItem(
                          item: navItems[index],
                          isActive: index == _currentIndex,
                          onTap: () => setState(() => _currentIndex = index),
                        );
                      }),
                    ),
                  ),
                  // Floating circle button muncul di atas bar
                  Positioned(
                    top: -20,
                    child: _FloatingCircleButton(
                      item: navItems[floatingIdx],
                      isActive: _currentIndex == floatingIdx,
                      onTap: () => setState(() => _currentIndex = floatingIdx),
                      size: 66,
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(navItems.length, (index) {
                    return _NavIconItem(
                      item: navItems[index],
                      isActive: index == _currentIndex,
                      onTap: () => setState(() => _currentIndex = index),
                    );
                  }),
                ),
              ),
      ),
    );
  }
}

// ── Widget helpers (dulu di floating_bottom_navbar.dart) ──────────────────────

class _NavIconItem extends StatelessWidget {
  final FloatingNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIconItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                item.icon,
                key: ValueKey(isActive),
                // Active = putih terang, inactive = putih redup
                color: isActive ? Colors.white : Colors.white.withOpacity(0.45),
                size: 22,
              ),
            ),
            const SizedBox(height: 5),
            // Dot indicator pengganti label teks
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              height: 4,
              width: isActive ? 4 : 0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingCircleButton extends StatelessWidget {
  final FloatingNavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final double size;

  const _FloatingCircleButton({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Active = putih, inactive = biru lebih terang dari bar
          color: isActive ? Colors.white : const Color(0xFF1A8FFF),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.white.withOpacity(0.3),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              // Shadow lebih kuat saat active
              color: isActive
                  ? AppColors.primary.withOpacity(0.45)
                  : Colors.black.withOpacity(0.25),
              blurRadius: isActive ? 18 : 10,
              spreadRadius: isActive ? 2 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: AnimatedScale(
            scale: isActive ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: Icon(
              item.icon,
              // Active = biru (kontras dengan bg putih), inactive = putih
              color: isActive ? AppColors.primary : Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
