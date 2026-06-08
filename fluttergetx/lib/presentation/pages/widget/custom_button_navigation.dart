import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttergetx/presentation/bindings/chat_binding.dart';
import 'package:fluttergetx/presentation/bindings/diagnosis_binding.dart';
import 'package:fluttergetx/presentation/bindings/article_binding.dart';
import 'package:fluttergetx/presentation/bindings/hospital_binding.dart';
import 'package:fluttergetx/presentation/controllers/auth_controller.dart';
import 'package:fluttergetx/presentation/pages/article/article_list_page.dart';
import 'package:fluttergetx/presentation/pages/chat/patient/chat_list_page.dart';
import 'package:fluttergetx/presentation/pages/diagnosis/diagnosis_history_page.dart';
import 'package:fluttergetx/presentation/pages/home/admin_home_page.dart';
import 'package:fluttergetx/presentation/pages/home/home_page.dart';
import 'package:fluttergetx/presentation/pages/hospital/patient_hospital_page.dart';
import 'package:fluttergetx/presentation/pages/profile/profile_page.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';

class MainNavigationWrapper extends StatefulWidget {
  final int initialIndex;
  const MainNavigationWrapper({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper>
    with TickerProviderStateMixin {
  late PersistentTabController _controller;

  // Animation controllers untuk tiap tab (jika ingin menggunakan AnimatedIcons)
  late AnimationController _homeAnimController;
  late AnimationController _mapAnimController;
  late AnimationController _chatAnimController;
  late AnimationController _profileAnimController;
  late AnimationController _diagnosisController;

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: widget.initialIndex);

    if (!Get.isRegistered<Dio>()) {
      Get.put<Dio>(Dio(), permanent: true);
    }

    // Inisialisasi controller animasi untuk icon
    _homeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _mapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _chatAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _profileAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _diagnosisController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    DiagnosisBinding().dependencies();
    HospitalBinding().dependencies();
    ArticleBinding().dependencies();

    _determineRole();
  }

  Future<void> _determineRole() async {
    try {
      // Coba ambil dari AuthController jika ter-registrasi dan punya user
      if (Get.isRegistered<AuthController>()) {
        final auth = Get.find<AuthController>();
        // Sesuaikan akses properti user/role sesuai implementasi AuthController-mu
        // auth.currentUser adalah Rxn<UserEntity>, ambil nilai aslinya lewat .value
        final role = auth.currentUser.value?.role;
        if (role != null && role.toString().toLowerCase() == 'admin') {
          setState(() => _isAdmin = true);
          return;
        }
      }

      // Fallback: cek secure storage
      final storage = const FlutterSecureStorage();
      final storedRole = await storage.read(key: 'role') ?? '';
      setState(() => _isAdmin = storedRole.toLowerCase() == 'admin');
    } catch (_) {
      // ignore, biarkan default false
    }
  }

  @override
  void dispose() {
    _homeAnimController.dispose();
    // _mapAnimController.dispose();
    _chatAnimController.dispose();
    _profileAnimController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  // List<Widget> _buildScreens() {
  //   return [
  //     const HomePage(), // Content Dashboard
  //     // const PatientHospitalPage(),
  //     const PatientChatListPage(),
  //     const DiagnosisHistoryPage(),
  //     const ProfilePage(),
  //     const AdminHomePage(),
  //   ];
  // }
  List<Widget> _buildScreens() {
    if (_isAdmin) {
      return [
        const AdminHomePage(),
        const ArticleListPage(),
        const ProfilePage(),
      ];
    }

    // patient / default
    // Patient screens
    return [
      const HomePage(),
      const PatientHospitalPage(), // pasien lihat peta
      const PatientChatListPage(),
      const DiagnosisHistoryPage(),
      const ArticleListPage(), // New Articles tab
      const ProfilePage(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    if (_isAdmin) {
        return [
          PersistentBottomNavBarItem(
            icon: const Icon(Icons.admin_panel_settings),
            title: "Admin",
            activeColorPrimary: AppColors.white,
            activeColorSecondary: AppColors.primary,
            inactiveColorPrimary: Colors.grey,
            inactiveColorSecondary: Colors.transparent,
          ),
          PersistentBottomNavBarItem(
            icon: const Icon(Icons.article),
            title: "Artikel",
            activeColorPrimary: AppColors.white,
            activeColorSecondary: AppColors.primary,
            inactiveColorPrimary: Colors.grey,
            inactiveColorSecondary: Colors.transparent,
          ),
          PersistentBottomNavBarItem(
            icon: const Icon(Icons.person_sharp),
            title: "Profil",
            activeColorPrimary: AppColors.white,
            activeColorSecondary: AppColors.primary,
            inactiveColorPrimary: Colors.grey,
            inactiveColorSecondary: Colors.transparent,
            iconAnimationController: _profileAnimController,
          ),
        ];
    }

    // patient nav items
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home_filled),
        title: "Home",
        activeColorPrimary: AppColors.white,
        activeColorSecondary: AppColors.primary,
        inactiveColorPrimary: Colors.grey,
        inactiveColorSecondary: Colors.transparent,
        iconAnimationController: _homeAnimController,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.location_on_rounded),
        title: "Lokasi",
        activeColorPrimary: AppColors.white,
        activeColorSecondary: AppColors.primary,
        inactiveColorPrimary: Colors.grey,
        inactiveColorSecondary: Colors.transparent,
        iconAnimationController: _mapAnimController,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        title: "Chat",
        activeColorPrimary: AppColors.white,
        activeColorSecondary: AppColors.primary,
        inactiveColorPrimary: Colors.grey,
        inactiveColorSecondary: Colors.transparent,
        iconAnimationController: _chatAnimController,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.medical_information_rounded),
        title: "Diagnosis",
        activeColorPrimary: AppColors.white,
        activeColorSecondary: AppColors.primary,
        inactiveColorPrimary: Colors.grey,
        inactiveColorSecondary: Colors.transparent,
        iconAnimationController: _diagnosisController,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.article),
        title: "Artikel",
        activeColorPrimary: AppColors.white,
        activeColorSecondary: AppColors.primary,
        inactiveColorPrimary: Colors.grey,
        inactiveColorSecondary: Colors.transparent,
        iconAnimationController: null,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person_sharp),
        title: "Profil",
        activeColorPrimary: AppColors.white,
        activeColorSecondary: AppColors.primary,
        inactiveColorPrimary: Colors.grey,
        inactiveColorSecondary: Colors.transparent,
        iconAnimationController: _profileAnimController,
      ),
    ];
  }

  // List<PersistentBottomNavBarItem> _navBarsItems() {
  //   return [
  //     PersistentBottomNavBarItem(
  //       icon: const Icon(Icons.home_filled),
  //       title: "Home",
  //       activeColorPrimary: AppColors.primary,
  //       activeColorSecondary: Colors.white,
  //       inactiveColorPrimary: Colors.grey,
  //       iconAnimationController: _homeAnimController,
  //     ),
  //     // PersistentBottomNavBarItem(
  //     //   icon: const Icon(Icons.location_on_rounded),
  //     //   title: "Lokasi",
  //     //   activeColorPrimary: AppColors.primary,
  //     //   activeColorSecondary: Colors.white,
  //     //   inactiveColorPrimary: Colors.grey,
  //     //   iconAnimationController: _mapAnimController,
  //     // ),
  //     PersistentBottomNavBarItem(
  //       icon: const Icon(Icons.chat_bubble_outline_rounded),
  //       title: "Chat",
  //       activeColorPrimary: AppColors.primary,
  //       activeColorSecondary: Colors.white,
  //       inactiveColorPrimary: Colors.grey,
  //       iconAnimationController: _chatAnimController,
  //     ),
  //     PersistentBottomNavBarItem(
  //       icon: const Icon(Icons.medical_information_rounded),
  //       title: "Diagnosis",
  //       activeColorPrimary: AppColors.primary,
  //       activeColorSecondary: Colors.white,
  //       inactiveColorPrimary: Colors.grey,
  //       iconAnimationController: _diagnosisController,
  //     ),
  //     PersistentBottomNavBarItem(
  //       icon: const Icon(Icons.person_sharp),
  //       title: "Profil",
  //       activeColorPrimary: AppColors.primary,
  //       activeColorSecondary: Colors.white,
  //       inactiveColorPrimary: Colors.grey,
  //       iconAnimationController: _profileAnimController,
  //     ),
  //   ];
  // }

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _buildScreens(),
      items: _navBarsItems(),
      confineToSafeArea: true,
      backgroundColor: Colors.white,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: true,
      stateManagement: true,
      hideNavigationBarWhenKeyboardAppears: true,
      decoration: NavBarDecoration(
        borderRadius: BorderRadius.circular(0.0),
        colorBehindNavBar: Colors.white,
        boxShadow: [
          const BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      navBarStyle: NavBarStyle.style10, // Mengaktifkan Style 10
    );
  }
}
