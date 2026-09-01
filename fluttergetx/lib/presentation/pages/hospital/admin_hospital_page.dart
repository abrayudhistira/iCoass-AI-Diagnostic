import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/core/utils/image_url_helper.dart';
import 'package:fluttergetx/domain/entities/hospital_entity.dart';
import 'package:fluttergetx/presentation/controllers/hospital_controller.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/loading_overlay.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/map_action_buttons.dart';
import 'package:fluttergetx/presentation/pages/widget/chat/radius_filter_overlay.dart';
import 'package:fluttergetx/presentation/pages/widget/hospital/admin_hospital_form.dart';
import 'package:fluttergetx/presentation/pages/widget/hospital/admin_hospital_map_section.dart';
import 'package:fluttergetx/presentation/pages/widget/hospital/admin_map_guidance.dart';
import 'package:fluttergetx/presentation/widgets/common_snackbar.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// [AdminHospitalPage] — antarmuka manajemen spasial data RSGM untuk administrator.
/// Terintegrasi penuh dengan Google Maps SDK untuk akurasi data geolokasi.
/// UI/UX disamakan dengan PatientHospitalPage: immersive AppBar, layered Stack, haptic feedback, AppColors.
class AdminHospitalPage extends StatefulWidget {
  const AdminHospitalPage({super.key});

  @override
  State<AdminHospitalPage> createState() => _AdminHospitalPageState();
}

class _AdminHospitalPageState extends State<AdminHospitalPage> with SingleTickerProviderStateMixin {
  final HospitalController controller = Get.find<HospitalController>();

  // Kendali Form Tekstual
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Pengendali Asinkron Kamera Google Maps
  final Completer<GoogleMapController> _mapControllerCompleter = Completer<GoogleMapController>();

  // State UI Lokal Lokasi Spasial (Baseline: Pusat Yogyakarta)
  LatLng _selectedLatLng = const LatLng(-7.7956, 110.3695);
  HospitalEntity? _selectedHospital;
  bool _isFormVisible = false;
  String? _networkImageUrl;

  // Animasi untuk form slide-up
  late AnimationController _formAnimationController;
  late Animation<Offset> _formSlideAnimation;

  @override
  void initState() {
    super.initState();

    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchHospitals();
    });
  }

  @override
  void dispose() {
    _formAnimationController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _nameController.clear();
    _phoneController.clear();
    _descController.clear();
    _addressController.clear();
    _selectedHospital = null;
    _networkImageUrl = null;
    controller.selectedImage.value = null;
  }

  void _showFormForCreate(LatLng point) {
    HapticFeedback.lightImpact();
    setState(() {
      _resetForm();
      _selectedLatLng = point;
      _isFormVisible = true;
    });
    _formAnimationController.forward();
    _animateCameraToPosition(point);
  }

  void _showFormForUpdate(HospitalEntity hospital) {
    HapticFeedback.lightImpact();
    final String? imageUrl = hospital.imageUrl?.isNotEmpty == true
        ? ImageUrlHelper.resolve(hospital.imageUrl)
        : null;

    setState(() {
      _selectedHospital = hospital;
      _selectedLatLng = LatLng(hospital.latitude, hospital.longitude);
      _nameController.text = hospital.name;
      _addressController.text = hospital.address;
      _phoneController.text = hospital.phone;
      _descController.text = hospital.description ?? '';
      _networkImageUrl = imageUrl;
      _isFormVisible = true;
    });
    _formAnimationController.forward();
    _animateCameraToPosition(_selectedLatLng);
  }

  void _hideForm() {
    HapticFeedback.lightImpact();
    _formAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isFormVisible = false;
          _resetForm();
        });
      }
    });
  }

  Future<void> _animateCameraToPosition(LatLng target) async {
    try {
      if (_mapControllerCompleter.isCompleted) {
        final GoogleMapController mapController = await _mapControllerCompleter.future;
        await mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 14.5),
          ),
        );
      }
    } catch (e) {
      debugPrint('[MAP ERROR] Gagal melakukan reposisi kamera: $e');
    }
  }

  Future<void> _submitData() async {
    if (_nameController.text.trim().isEmpty || _addressController.text.trim().isEmpty) {
      AppSnackbar.warning("Atribut Nama dan Alamat rumah sakit wajib dilengkapi.", title: "Validasi Gagal");
      return;
    }

    bool isSuccess = false;

    if (_selectedHospital == null) {
      await controller.createHospital(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        description: _descController.text.trim(),
        lat: _selectedLatLng.latitude,
        lng: _selectedLatLng.longitude,
      );
      isSuccess = true;
    } else {
      isSuccess = await controller.updateHospital(
        id: _selectedHospital!.id!,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        description: _descController.text.trim(),
        lat: _selectedLatLng.latitude,
        lng: _selectedLatLng.longitude,
        imageFile: controller.selectedImage.value,
      );
    }

    if (isSuccess) {
      _hideForm();
    }
  }

  Future<void> _handleDeleteHospital(int id) async {
    await controller.deleteHospital(id);
    _hideForm();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Padding(
        padding: EdgeInsets.only(
          top: kToolbarHeight + MediaQuery.of(context).padding.top,
        ),
        child: Stack(
          children: <Widget>[
            // Layer 1
            Obx(
              () => AdminHospitalMapSection(
                key: ValueKey(controller.selectedRadius.value),
                controller: controller,
                selectedLatLng: _selectedLatLng,
                isFormVisible: _isFormVisible,
                selectedHospital: _selectedHospital,
                onMapCreated: (GoogleMapController mapController) {
                  if (!_mapControllerCompleter.isCompleted) {
                    _mapControllerCompleter.complete(mapController);
                  }
                },
                onLongPress: _showFormForCreate,
                onTap: () => _isFormVisible ? _hideForm() : null,
                onHospitalTap: _showFormForUpdate,
              ),
            ),

            // Layer 2
            RadiusFilterOverlay(controller: controller),

            // Layer 3
            Obx(() => MapActionButtons(
              onMoveCamera: (target, zoom) => _animateCameraToPosition(target),
              userLocation: _selectedLatLng,
              isLocating: controller.isLoading.value,
              onLocate: () => _animateCameraToPosition(_selectedLatLng),
            )),

            // Layer 4 - Half-screen bottom sheet
            _isFormVisible
                ? Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: MediaQuery.of(context).size.height * 0.55, // ~55% of screen height
                    child: SlideTransition(
                      position: _formSlideAnimation,
                      child: Material(
                        elevation: 8,
                        shadowColor: Colors.black.withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                        child: AdminHospitalForm(
                          controller: controller,
                          selectedHospital: _selectedHospital,
                          selectedLatLng: _selectedLatLng,
                          networkImageUrl: _networkImageUrl,
                          onSubmit: _submitData,
                          onCancel: _hideForm,
                          onDelete: _handleDeleteHospital,
                          nameController: _nameController,
                          addressController: _addressController,
                          phoneController: _phoneController,
                          descController: _descController,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),

            // Layer 5 - Positioned below RadiusFilterOverlay (which is at top: 16, height ~70)
            // Button aligned left, popup will be centered via overlay
            Positioned(
              top: 125.0,
              left: 16.0,
              child: AdminMapGuidance(
                isFormVisible: _isFormVisible,
              ),
            ),

            // Layer 6
            Obx(() => LoadingOverlay(isVisible: controller.isLoading.value)),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.97),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
      title: const _AdminAppBarTitle(),
      actions: [
        _RefreshButton(onRefresh: () => controller.fetchHospitals()),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _AdminAppBarTitle extends StatelessWidget {
  const _AdminAppBarTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_hospital_rounded,
            color: AppColors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kelola RSGM',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              'Administrator Mode',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textGrey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final VoidCallback onRefresh;

  const _RefreshButton({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Refresh Data',
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onRefresh();
          },
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.refresh_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}