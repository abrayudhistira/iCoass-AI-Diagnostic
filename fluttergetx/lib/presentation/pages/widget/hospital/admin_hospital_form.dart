import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:fluttergetx/domain/entities/hospital_entity.dart';
import 'package:fluttergetx/presentation/controllers/hospital_controller.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// [AdminHospitalForm] — Form editor kontekstual untuk CRUD RSGM (Create/Update).
/// Styling disamakan dengan PatientHospitalPage: AppColors, consistent spacing, rounded corners, shadows.
class AdminHospitalForm extends StatelessWidget {
  final HospitalController controller;
  final HospitalEntity? selectedHospital;
  final LatLng selectedLatLng;
  final String? networkImageUrl;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final Future<void> Function(int) onDelete;
  final TextEditingController nameController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final TextEditingController descController;

  const AdminHospitalForm({
    super.key,
    required this.controller,
    required this.selectedHospital,
    required this.selectedLatLng,
    required this.networkImageUrl,
    required this.onSubmit,
    required this.onCancel,
    required this.onDelete,
    required this.nameController,
    required this.addressController,
    required this.phoneController,
    required this.descController,
  });

  void _showDeleteConfirmation(int hospitalId) {
    Get.defaultDialog(
      title: "Hapus RSGM",
      titleStyle: const TextStyle(
        color: AppColors.error,
        fontWeight: FontWeight.w800,
        fontSize: 18,
      ),
      middleText: "Apakah Anda yakin akan menghapus data ${selectedHospital!.name}?",
      middleTextStyle: const TextStyle(
        color: AppColors.textMain,
        fontSize: 14,
      ),
      textConfirm: "Hapus",
      textCancel: "Batal",
      confirmTextColor: AppColors.white,
      cancelTextColor: AppColors.textMain,
      buttonColor: AppColors.error,
      backgroundColor: AppColors.white,
      radius: 16,
      onConfirm: () {
        onDelete(hospitalId);
        Get.back();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _dragHandle(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha:0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      selectedHospital == null ? Icons.add_location_alt_rounded : Icons.edit_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedHospital == null ? "Tambah RSGM Baru" : "Edit Data RSGM",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.textMain,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          selectedHospital == null
                              ? "Isi detail rumah sakit di lokasi terpilih"
                              : "Perbarui informasi ${selectedHospital!.name}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildField(nameController, "Nama Rumah Sakit", Icons.business_rounded),
              const SizedBox(height: 14),
              _buildField(addressController, "Alamat", Icons.map_rounded),
              const SizedBox(height: 14),
              // Phone field with +62 prefix (matching profile page)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Kontak Layanan",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // +62 prefix container
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(14),
                            bottomLeft: Radius.circular(14),
                          ),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        child: const Text(
                          '+62',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textMain,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 14, color: AppColors.textMain),
                          decoration: InputDecoration(
                            isDense: true,
                            labelText: "Nomor Telepon",
                            labelStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                            floatingLabelStyle: const TextStyle(color: AppColors.primary, fontSize: 13),
                            prefixIcon: Icon(Icons.phone_rounded, size: 20, color: AppColors.primary.withValues(alpha: 0.7)),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(14),
                                bottomRight: Radius.circular(14),
                              ),
                              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(14),
                                bottomRight: Radius.circular(14),
                              ),
                              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(14),
                                bottomRight: Radius.circular(14),
                              ),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(14),
                                bottomRight: Radius.circular(14),
                              ),
                              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            counterText: '',
                          ),
                          maxLength: 13,
                          onChanged: (value) {
                            // Remove leading zeros
                            if (value.startsWith('0')) {
                              phoneController.value = TextEditingValue(
                                text: value.replaceFirst(RegExp(r'^0+'), ''),
                                selection: TextSelection.collapsed(offset: value.replaceFirst(RegExp(r'^0+'), '').length),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildField(descController, "Deskripsi", Icons.description_rounded, maxLines: 3),
              const SizedBox(height: 20),
              _buildImagePickerMini(),
              const SizedBox(height: 20),
              // Delete button (only visible in edit mode) - full width like logout button
              if (selectedHospital != null)
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: BorderSide(color: AppColors.error.withValues(alpha: 0.3), width: 1.5),
                          foregroundColor: AppColors.error,
                        ),
                        onPressed: controller.isLoading.value ? null : () => _showDeleteConfirmation(selectedHospital!.id!),
                        icon: const Icon(Icons.delete_forever_rounded, size: 20),
                        label: const Text(
                          "HAPUS RS",
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: controller.isLoading.value ? null : onCancel,
                      child: const Text(
                        "BATAL",
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                        ),
                        onPressed: controller.isLoading.value ? null : onSubmit,
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: AppColors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                selectedHospital == null ? "SIMPAN" : "EDIT",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.textGrey.withValues(alpha:0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: AppColors.textMain),
      decoration: InputDecoration(
        isDense: true,
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textGrey, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: AppColors.primary, fontSize: 13),
        prefixIcon: Icon(icon, size: 20, color: AppColors.primary.withValues(alpha:0.7)),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha:0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary.withValues(alpha:0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildImagePickerMini() {
    return Obx(
      () {
        final bool hasNewFile = controller.selectedImage.value != null;
        final bool hasNetworkImage = networkImageUrl != null && networkImageUrl!.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Foto Rumah Sakit",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.all(color: AppColors.primary.withValues(alpha:0.2)),
                    borderRadius: BorderRadius.circular(14),
                    image: hasNewFile
                        ? DecorationImage(
                            image: FileImage(controller.selectedImage.value!),
                            fit: BoxFit.cover,
                          )
                        : hasNetworkImage
                            ? DecorationImage(
                                image: NetworkImage(networkImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha:0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: (!hasNewFile && !hasNetworkImage)
                      ? Icon(Icons.image_rounded, color: AppColors.textGrey.withValues(alpha:0.5), size: 28)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: AppColors.primary.withValues(alpha:0.3), width: 1.5),
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: controller.pickImage,
                    icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    label: Text(
                      hasNewFile
                          ? "Ubah Foto"
                          : hasNetworkImage
                              ? "Ubah Foto"
                              : "Tambah Foto",
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}