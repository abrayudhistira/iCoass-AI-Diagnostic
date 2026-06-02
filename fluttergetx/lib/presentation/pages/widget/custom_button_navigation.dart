import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttergetx/presentation/bindings/chat_binding.dart';
import 'package:fluttergetx/presentation/bindings/diagnosis_binding.dart';
import 'package:fluttergetx/presentation/bindings/hospital_binding.dart';
import 'package:fluttergetx/presentation/pages/chat/patient/chat_list_page.dart';
import 'package:fluttergetx/presentation/pages/diagnosis/diagnosis_history_page.dart';
import 'package:fluttergetx/presentation/pages/home/home_page.dart';
import 'package:fluttergetx/presentation/pages/hospital/patient_hospital_page.dart';
import 'package:fluttergetx/presentation/pages/profile/profile_page.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> with TickerProviderStateMixin {
  late PersistentTabController _controller;
  
  // Animation controllers untuk tiap tab (jika ingin menggunakan AnimatedIcons)
  late AnimationController _homeAnimController;
  late AnimationController _mapAnimController;
  late AnimationController _chatAnimController;
  late AnimationController _profileAnimController;
  late AnimationController _diagnosisController;
  

  @override
  void initState() {
    super.initState();
    _controller = PersistentTabController(initialIndex: 0);

    if (!Get.isRegistered<Dio>()) {
    Get.put<Dio>(Dio(), permanent: true);
  }
    
    // Inisialisasi controller animasi untuk icon
    _homeAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _mapAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _chatAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _profileAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _diagnosisController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    DiagnosisBinding().dependencies();
    HospitalBinding().dependencies();
    ChatBinding().dependencies();
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

  List<Widget> _buildScreens() {
    return [
      const HomePage(), // Content Dashboard
      // const PatientHospitalPage(), 
      const PatientChatListPage(),
      const DiagnosisHistoryPage(),
      const ProfilePage(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    return [
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.home_filled),
        title: "Home",
        activeColorPrimary: AppColors.primary,
        activeColorSecondary: Colors.white,
        inactiveColorPrimary: Colors.grey,
        iconAnimationController: _homeAnimController,
      ),
      // PersistentBottomNavBarItem(
      //   icon: const Icon(Icons.location_on_rounded),
      //   title: "Lokasi",
      //   activeColorPrimary: AppColors.primary,
      //   activeColorSecondary: Colors.white,
      //   inactiveColorPrimary: Colors.grey,
      //   iconAnimationController: _mapAnimController,
      // ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        title: "Chat",
        activeColorPrimary: AppColors.primary,
        activeColorSecondary: Colors.white,
        inactiveColorPrimary: Colors.grey,
        iconAnimationController: _chatAnimController,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.medical_information_rounded),
        title: "Diagnosis",
        activeColorPrimary: AppColors.primary,
        activeColorSecondary: Colors.white,
        inactiveColorPrimary: Colors.grey,
        iconAnimationController: _diagnosisController,
      ),
      PersistentBottomNavBarItem(
        icon: const Icon(Icons.person_sharp),
        title: "Profil",
        activeColorPrimary: AppColors.primary,
        activeColorSecondary: Colors.white,
        inactiveColorPrimary: Colors.grey,
        iconAnimationController: _profileAnimController,
      ),
    ];
  }

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
          const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      navBarStyle: NavBarStyle.style10, // Mengaktifkan Style 10
    );
  }
}