import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttergetx/presentation/pages/widget/home/diagnosis_banner_card.dart';
import 'package:fluttergetx/presentation/pages/widget/home/features_carousel.dart';
import 'package:fluttergetx/presentation/pages/widget/home/hospital_map_preview.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import '../../../core/constants/colors.dart';
import '../../controllers/auth_controller.dart';
import '../widget/home/custom_home_header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: DashboardView(),
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: _handleRefresh,
      builder: (context, child, controller) {
        return Stack(
          alignment: Alignment.topCenter,
          children: <Widget>[
            if (!controller.isIdle)
              Positioned(
                top: 25.0 * controller.value,
                child: SizedBox(
                  height: 60,
                  child: Lottie.asset('assets/lottie/loading_animation.json',
                      fit: BoxFit.contain),
                ),
              ),
            Transform.translate(
              offset: Offset(0, 80.0 * controller.value),
              child: child,
            ),
          ],
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const CustomHomeHeader(),
            const SizedBox(height: 20),
            const DiagnosisBannerCard(),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fitur Tersedia',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const FeaturesCarousel(),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'RSGM Terdekat dengan Anda',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const HospitalMapPreview(),
            const SizedBox(height: 24),
            // const ShowMoreContainer(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}