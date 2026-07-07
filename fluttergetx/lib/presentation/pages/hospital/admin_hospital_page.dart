import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../controllers/hospital_controller.dart';
import '../../../domain/entities/hospital_entity.dart';

/// [AdminHospitalPage] — antarmuka manajemen spasial data RSGM untuk administrator.
/// Terintegrasi penuh dengan Google Maps SDK untuk akurasi data geolokasi.
class AdminHospitalPage extends StatefulWidget {
  const AdminHospitalPage({super.key});

  @override
  State<AdminHospitalPage> createState() => _AdminHospitalPageState();
}

class _AdminHospitalPageState extends State<AdminHospitalPage> {
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
  HospitalEntity? _selectedHospital; // Null: Create Mode | Valid Instance: Update Mode
  bool _isFormVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchHospitals();
    });
  }

  void _resetForm() {
    _nameController.clear();
    _phoneController.clear();
    _descController.clear();
    _addressController.clear();
    _selectedHospital = null;
    controller.selectedImage.value = null;
  }

  void _showFormForCreate(LatLng point) {
    setState(() {
      _resetForm();
      _selectedLatLng = point;
      _isFormVisible = true;
    });
    _animateCameraToPosition(point);
  }

  void _showFormForUpdate(HospitalEntity hospital) {
    setState(() {
      _selectedHospital = hospital;
      _selectedLatLng = LatLng(hospital.latitude, hospital.longitude);
      _nameController.text = hospital.name;
      _addressController.text = hospital.address;
      _phoneController.text = hospital.phone ?? '';
      _descController.text = hospital.description ?? '';
      _isFormVisible = true;
    });
    _animateCameraToPosition(_selectedLatLng);
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

  /// Membangun koleksi marker Google Maps secara reaktif kombinasi internal state & database state
  Set<Marker> _buildMapMarkers() {
    final Set<Marker> markers = {};

    // 1. Marker Transien Eksplisit (Indikator titik koordinat penambahan/modifikasi aktif)
    if (_isFormVisible) {
      markers.add(
        Marker(
          markerId: const MarkerId('active_transient_marker'),
          position: _selectedLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Lokasi Terpilih'),
        ),
      );
    }

    // 2. Kumpulan Marker Persisten (Kombinasi Obx Objek Rumah Sakit dari DB)
    for (var hospital in controller.hospitals) {
      markers.add(
        Marker(
          markerId: MarkerId('hospital_id_${hospital.id}'),
          position: LatLng(hospital.latitude, hospital.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: hospital.name,
            snippet: hospital.address,
          ),
          onTap: () => _showFormForUpdate(hospital),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelola Rumah Sakit',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => controller.fetchHospitals(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Komponen Visual Spasial Utama (Google Maps)
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                _buildMapSection(),
                _buildTopGuidance(),
                if (_selectedHospital != null) _buildDeleteButtonOverlay(),
              ],
            ),
          ),

          // Komponen Manipulasi Atribut Data (Contextual Form Editor)
          if (_isFormVisible)
            Expanded(
              flex: 2,
              child: _buildFormSection(),
            ),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    return Obx(
      () => GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _selectedLatLng,
          zoom: 13.0,
        ),
        markers: _buildMapMarkers(),
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
        zoomControlsEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          if (!_mapControllerCompleter.isCompleted) {
            _mapControllerCompleter.complete(controller);
          }
        },
        onLongPress: (LatLng point) {
          HapticFeedback.mediumImpact();
          _showFormForCreate(point);
        },
        onTap: (LatLng point) {
          setState(() => _isFormVisible = false);
        },
      ),
    );
  }

  Widget _buildTopGuidance() {
    return Positioned(
      top: 15,
      left: 15,
      right: 15,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.blueGrey[700], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isFormVisible
                    ? "Lengkapi parameter entitas di bawah untuk persistensi data."
                    : "Tekan lama pada bidang peta untuk mendaftarkan RSGM baru.",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey[900],
                ),
              ),
            ),
            if (_isFormVisible)
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => setState(() => _isFormVisible = false),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButtonOverlay() {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton.extended(
        heroTag: 'fab_delete_hospital',
        onPressed: () {
          Get.defaultDialog(
            title: "Destruksi Data",
            middleText: "Apakah Anda yakin akan menghapus data ${_selectedHospital?.name}?",
            textConfirm: "Hapus",
            textCancel: "Batal",
            confirmTextColor: Colors.white,
            buttonColor: Colors.red,
            onConfirm: () {
              if (_selectedHospital?.id != null) {
                controller.deleteHospital(_selectedHospital!.id!);
                setState(() => _isFormVisible = false);
              }
              Get.back();
            },
          );
        },
        label: const Text("Hapus RS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -3),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _selectedHospital == null ? "Registrasi RSGM Baru" : "Modifikasi Atribut RSGM",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.blueGrey[900]),
              ),
              const SizedBox(height: 12),
              _buildField(_nameController, "Nama Resmi Rumah Sakit", Icons.business_rounded),
              const SizedBox(height: 10),
              _buildField(_addressController, "Alamat Fisik Geografis", Icons.map_rounded),
              const SizedBox(height: 10),
              _buildField(
                _phoneController,
                "Nomor Kontak/Telepon Layanan",
                Icons.phone_rounded,
                keyboard: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              _buildField(_descController, "Deskripsi Operasional", Icons.description_rounded),
              const SizedBox(height: 16),
              _buildImagePickerMini(),
              const SizedBox(height: 20),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    onPressed: controller.isLoading.value ? null : _submitData,
                    child: controller.isLoading.value
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            _selectedHospital == null ? "SIMPAN ENTITAS" : "KONFIRMASI PEMBARUAN",
                            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueGrey[600], fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: Colors.blueGrey[400]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey[800]!, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildImagePickerMini() {
    return Obx(
      () => Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              image: controller.selectedImage.value != null
                  ? DecorationImage(
                      image: FileImage(controller.selectedImage.value!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: controller.selectedImage.value == null
                ? Icon(Icons.image_rounded, color: Colors.grey[400], size: 24)
                : null,
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.blueGrey[300]!),
            ),
            onPressed: controller.pickImage,
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: const Text("Pilih Foto Media", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitData() async {
    if (_nameController.text.trim().isEmpty || _addressController.text.trim().isEmpty) {
      Get.snackbar(
        "Validasi Gagal",
        "Atribut Nama dan Alamat rumah sakit wajib dilengkapi.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[800],
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
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
      setState(() {
        _isFormVisible = false;
        _resetForm();
      });
    }
  }
}