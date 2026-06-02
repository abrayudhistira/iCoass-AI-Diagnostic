import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

// ─── App Colors ───────────────────────────────────────────────────────────────
class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color secondary = Color(0xFFE3F2FD);
  static const Color background = Color(0xFFF5F9FC);
  static const Color textMain = Color(0xFF455A64);
  static const Color textGrey = Color(0xFF757575);
  static const Color success = Color(0xFF66BB6A);
  static const Color error = Color(0xFFE57373);
  static const Color white = Colors.white;
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.find<AuthController>();

  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _birthDateController;
  late TextEditingController _addressController;
  String? _selectedGender;

  // Track field yang sudah diubah untuk highlight
  final Set<String> _dirtyFields = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final user = _authController.currentUser.value;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _birthDateController = TextEditingController(text: user?.birthDate ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _selectedGender = user?.gender;

    // Listener untuk track perubahan
    for (final entry in {
      'fullName': _fullNameController,
      'username': _usernameController,
      'email': _emailController,
      'phone': _phoneController,
      'birthDate': _birthDateController,
      'address': _addressController,
    }.entries) {
      entry.value.addListener(() {
        setState(() => _dirtyFields.add(entry.key));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar preview ─────────────────────────────────────
                    _buildAvatarPreview(),
                    const SizedBox(height: 28),

                    // ── Seksi: Informasi Akun ─────────────────────────────
                    _sectionLabel('Informasi Akun'),
                    const SizedBox(height: 12),
                    _buildCard([
                      _buildField(
                        controller: _usernameController,
                        label: 'Username',
                        icon: Icons.alternate_email_rounded,
                        fieldKey: 'username',
                        keyboardType: TextInputType.text,
                      ),
                      _buildDivider(),
                      _buildField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_rounded,
                        fieldKey: 'email',
                        keyboardType: TextInputType.emailAddress,
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // ── Seksi: Data Personal ──────────────────────────────
                    _sectionLabel('Data Personal'),
                    const SizedBox(height: 12),
                    _buildCard([
                      _buildField(
                        controller: _fullNameController,
                        label: 'Nama Lengkap',
                        icon: Icons.person_rounded,
                        fieldKey: 'fullName',
                      ),
                      _buildDivider(),
                      _buildField(
                        controller: _phoneController,
                        label: 'Nomor Telepon',
                        icon: Icons.phone_rounded,
                        fieldKey: 'phone',
                        keyboardType: TextInputType.phone,
                      ),
                      _buildDivider(),
                      _buildGenderPicker(),
                      _buildDivider(),
                      _buildDateField(),
                      _buildDivider(),
                      _buildField(
                        controller: _addressController,
                        label: 'Alamat',
                        icon: Icons.location_on_rounded,
                        fieldKey: 'address',
                        maxLines: 3,
                      ),
                    ]),

                    const SizedBox(height: 32),

                    // ── Tombol Simpan ─────────────────────────────────────
                    Obx(() => _buildSaveButton()),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Profil',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Perbarui informasi akunmu',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar preview dengan inisial ─────────────────────────────────────────
  Widget _buildAvatarPreview() {
    return Center(
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary,
              child: Obx(() {
                final name = _authController.currentUser.value?.fullName ?? '';
                return Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
          // Edit badge
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textGrey,
        letterSpacing: 0.8,
      ),
    );
  }

  // ── Card pembungkus field ─────────────────────────────────────────────────
  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.secondary);

  // ── Text field di dalam card ───────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String fieldKey,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final isDirty = _dirtyFields.contains(fieldKey);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.textMain,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 13,
            color: isDirty ? AppColors.primary : AppColors.textGrey,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              margin: const EdgeInsets.all(10),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDirty
                    ? AppColors.primary.withOpacity(0.12)
                    : AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDirty ? AppColors.primary : AppColors.textGrey,
                size: 17,
              ),
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          suffixIcon: isDirty
              ? const Icon(Icons.circle, color: AppColors.primary, size: 8)
              : null,
        ),
        validator: (v) => v == null || v.isEmpty ? '$label wajib diisi' : null,
      ),
    );
  }

  // ── Gender picker ─────────────────────────────────────────────────────────
  Widget _buildGenderPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _selectedGender != null
                  ? AppColors.primary.withOpacity(0.12)
                  : AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.wc_rounded,
              color: _selectedGender != null
                  ? AppColors.primary
                  : AppColors.textGrey,
              size: 17,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jenis Kelamin',
                  style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _genderChip('L', 'Laki-laki', Icons.male_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _genderChip(
                        'P',
                        'Perempuan',
                        Icons.female_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genderChip(String value, String label, IconData icon) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedGender = value;
        _dirtyFields.add('gender');
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.secondary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textGrey,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Date picker field ─────────────────────────────────────────────────────
  Widget _buildDateField() {
    final isDirty = _dirtyFields.contains('birthDate');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate:
                DateTime.tryParse(_birthDateController.text) ?? DateTime(2000),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            final formatted =
                '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            _birthDateController.text = formatted;
            setState(() => _dirtyFields.add('birthDate'));
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: _birthDateController,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.textMain,
            ),
            decoration: InputDecoration(
              labelText: 'Tanggal Lahir',
              labelStyle: TextStyle(
                fontSize: 13,
                color: isDirty ? AppColors.primary : AppColors.textGrey,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDirty
                        ? AppColors.primary.withOpacity(0.12)
                        : AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: isDirty ? AppColors.primary : AppColors.textGrey,
                    size: 17,
                  ),
                ),
              ),
              suffixIcon: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textGrey,
                size: 20,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  // ── Tombol simpan ─────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    final isLoading = _authController.isLoading.value;
    final hasChanges = _dirtyFields.isNotEmpty;
    return GestureDetector(
      onTap: (isLoading || !hasChanges) ? null : _handleUpdate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: hasChanges && !isLoading
              ? AppColors.primary
              : AppColors.textGrey.withOpacity(0.25),
          borderRadius: BorderRadius.circular(16),
          boxShadow: hasChanges && !isLoading
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasChanges ? Icons.check_rounded : Icons.edit_off_rounded,
                      color: hasChanges ? Colors.white : AppColors.textGrey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasChanges ? 'Simpan Perubahan' : 'Belum ada perubahan',
                      style: TextStyle(
                        color: hasChanges ? Colors.white : AppColors.textGrey,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _handleUpdate() {
    if (_formKey.currentState!.validate()) {
      _authController.updateProfile(
        username: _usernameController.text,
        email: _emailController.text,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        birthDate: _birthDateController.text,
        gender: _selectedGender ?? 'L',
        address: _addressController.text,
      );
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
