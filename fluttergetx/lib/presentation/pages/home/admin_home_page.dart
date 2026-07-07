import 'package:flutter/material.dart';
import 'package:fluttergetx/presentation/pages/widget/home/admin_banner_card.dart';
import 'package:fluttergetx/presentation/pages/widget/home/admin_menu_section.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(85), // Atur tinggi AppBar
        child: AppBar(
          title: const Padding(
            padding: EdgeInsets.only(top: 30.0, bottom: 8.0),
            child: Text(
              'iCoass Admin Center',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          backgroundColor: AppColors.primaryDark,
          elevation: 0,
          centerTitle: false,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(25), // Radius di kiri & kanan bawah
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Banner Card
          const AdminBannerCard(),

          const SizedBox(height: 20),

          // Menu Section
          const Expanded(child: AdminMenuSection()),
        ],
      ),
    );
  }
}
