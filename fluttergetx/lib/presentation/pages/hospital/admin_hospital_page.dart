  import 'package:flutter/material.dart';
  import 'package:flutter_map/flutter_map.dart';
  import 'package:latlong2/latlong.dart';
  import 'package:get/get.dart';
  import '../../controllers/hospital_controller.dart';
  import '../../../domain/entities/hospital_entity.dart';

  class AdminHospitalPage extends StatefulWidget {
    const AdminHospitalPage({super.key});

    @override
    State<AdminHospitalPage> createState() => _AdminHospitalPageState();
  }

  class _AdminHospitalPageState extends State<AdminHospitalPage> {
    final controller = Get.find<HospitalController>();

    // Form Controllers
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _phoneController = TextEditingController();
    final TextEditingController _descController = TextEditingController();
    final TextEditingController _addressController = TextEditingController();

    // State UI Lokal
    LatLng _selectedLatLng = const LatLng(-7.7956, 110.3695);
    HospitalEntity? _selectedHospital; // Null jika mode "Tambah", Isi jika mode "Update"
    bool _isFormVisible = false;

    @override
    void initState() {
      super.initState();
      // Fetch data awal saat halaman dibuka
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
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Rumah Sakit'),
          backgroundColor: Colors.blueGrey,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.fetchHospitals(),
            )
          ],
        ),
        body: Column(
          children: [
            // Bagian 1: Maps (3/4 Layar atau fleksibel)
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

            // Bagian 2: Contextual Form (1/4 Layar/BottomSheet Style)
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
      return Obx(() => FlutterMap(
            options: MapOptions(
              initialCenter: _selectedLatLng,
              initialZoom: 13.0,
              onLongPress: (tapPosition, point) => _showFormForCreate(point),
              onTap: (_, __) {
                setState(() => _isFormVisible = false);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.icoass.app',
              ),
              MarkerLayer(
                markers: [
                  // Marker Aktif (yang sedang dipilih/ditambah)
                  if (_isFormVisible)
                    Marker(
                      point: _selectedLatLng,
                      width: 60,
                      height: 60,
                      child: const Icon(Icons.location_searching, color: Colors.blue, size: 40),
                    ),
                  // Marker dari Database
                  ...controller.hospitals.map((hospital) {
                    return Marker(
                      point: LatLng(hospital.latitude, hospital.longitude),
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _showFormForUpdate(hospital),
                        child: const Icon(Icons.location_on, color: Colors.red, size: 35),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ));
    }

    Widget _buildTopGuidance() {
      return Positioned(
        top: 15,
        left: 15,
        right: 15,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blueGrey, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isFormVisible 
                    ? "Lengkapi data di bawah untuk simpan perubahan."
                    : "Tekan lama (2 detik) pada peta untuk menambah RS baru.",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              if (_isFormVisible)
                IconButton(
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _isFormVisible = false),
                )
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
          onPressed: () {
            Get.defaultDialog(
              title: "Hapus Data",
              middleText: "Hapus ${_selectedHospital?.name} dari sistem?",
              textConfirm: "Hapus",
              confirmTextColor: Colors.white,
              onConfirm: () {
                controller.deleteHospital(_selectedHospital!.id!);
                setState(() => _isFormVisible = false);
                Get.back();
              },
            );
          },
          label: const Text("Hapus RS"),
          icon: const Icon(Icons.delete_forever),
          backgroundColor: Colors.red,
        ),
      );
    }

    Widget _buildFormSection() {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                _selectedHospital == null ? "Tambah Rumah Sakit Baru" : "Update Data Rumah Sakit",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(),
              _buildField(_nameController, "Nama RS", Icons.business),
              const SizedBox(height: 10),
              _buildField(_addressController, "Alamat", Icons.map),
              const SizedBox(height: 10),
              _buildField(_phoneController, "Telepon", Icons.phone, keyboard: TextInputType.phone),
              
              const SizedBox(height: 15),
              _buildImagePickerMini(),

              const SizedBox(height: 20),
              Obx(() => SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                  onPressed: controller.isLoading.value ? null : _submitData,
                  child: controller.isLoading.value 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_selectedHospital == null ? "SIMPAN DATA" : "UPDATE DATA"),
                ),
              )),
            ],
          ),
        ),
      );
    }

    Widget _buildField(TextEditingController ctrl, String label, IconData icon, {TextInputType keyboard = TextInputType.text}) {
      return TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          isDense: true,
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }

    Widget _buildImagePickerMini() {
      return Obx(() => Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              image: controller.selectedImage.value != null 
                ? DecorationImage(image: FileImage(controller.selectedImage.value!), fit: BoxFit.cover)
                : null,
            ),
            child: controller.selectedImage.value == null ? const Icon(Icons.image) : null,
          ),
          const SizedBox(width: 15),
          TextButton.icon(
            onPressed: controller.pickImage,
            icon: const Icon(Icons.camera_alt),
            label: const Text("Pilih Foto"),
          )
        ],
      ));
    }

    // void _submitData() {
    //   if (_nameController.text.isEmpty || _addressController.text.isEmpty) {
    //     Get.snackbar("Error", "Nama dan Alamat wajib diisi");
    //     return;
    //   }

    //   if (_selectedHospital == null) {
    //     // Logic Create
    //     controller.createHospital(
    //       name: _nameController.text,
    //       address: _addressController.text,
    //       phone: _phoneController.text,
    //       description: _descController.text,
    //       lat: _selectedLatLng.latitude,
    //       lng: _selectedLatLng.longitude,
    //     );
    //   } else {
    //     // Logic Update (Jika repository sudah mendukung update)
    //     // Jika belum, Anda bisa tambahkan method update di controller
    //     Get.snackbar("Info", "Fitur update sedang disiapkan.");
    //   }
      
    //   setState(() => _isFormVisible = false);
    // }
    Future<void> _submitData() async {
      if (_nameController.text.trim().isEmpty || _addressController.text.trim().isEmpty) {
        Get.snackbar(
          "Peringatan", 
          "Nama dan Alamat rumah sakit wajib diisi",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.withOpacity(0.8),
          colorText: Colors.white,
        );
        return;
      }

      bool isSuccess = false;

      if (_selectedHospital == null) {
        await controller.createHospital(
          name: _nameController.text,
          address: _addressController.text,
          phone: _phoneController.text,
          description: _descController.text,
          lat: _selectedLatLng.latitude,
          lng: _selectedLatLng.longitude,
        );
        isSuccess = true;
      } else {
        isSuccess = await controller.updateHospital(
          id: _selectedHospital!.id!,
          name: _nameController.text,
          address: _addressController.text,
          phone: _phoneController.text,
          description: _descController.text,
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