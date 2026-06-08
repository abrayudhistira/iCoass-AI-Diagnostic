import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';
import '../../controllers/auth_controller.dart';
import '../../../../domain/entities/user_entity.dart';

class UserFormPage extends StatefulWidget {
  const UserFormPage({super.key});

  @override
  State<UserFormPage> createState() => _UserFormPageState();
}

class _UserFormPageState extends State<UserFormPage> {
  final AuthController controller = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final UserEntity? userToEdit = Get.arguments as UserEntity?;

  late TextEditingController _usernameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _passwordCtrl;
  late TextEditingController _fullNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _birthDateCtrl;
  String _selectedGender = 'L';
  bool _obscurePassword = true;

  // Track field yang diubah
  final Set<String> _dirty = {};

  bool get _isEdit => userToEdit != null;

  @override
  void initState() {
    super.initState();
    _usernameCtrl  = TextEditingController(text: userToEdit?.username ?? '');
    _emailCtrl     = TextEditingController(text: userToEdit?.email ?? '');
    _passwordCtrl  = TextEditingController();
    _fullNameCtrl  = TextEditingController(text: userToEdit?.fullName ?? '');
    _phoneCtrl     = TextEditingController(text: userToEdit?.phone ?? '');
    _addressCtrl   = TextEditingController(text: userToEdit?.address ?? '');
    _birthDateCtrl = TextEditingController(text: userToEdit?.birthDate ?? '');
    _selectedGender = userToEdit?.gender ?? 'L';

    // Listener dirty tracking
    for (final e in {
      'username' : _usernameCtrl,
      'email'    : _emailCtrl,
      'password' : _passwordCtrl,
      'fullName' : _fullNameCtrl,
      'phone'    : _phoneCtrl,
      'address'  : _addressCtrl,
      'birthDate': _birthDateCtrl,
    }.entries) {
      e.value.addListener(() => setState(() => _dirty.add(e.key)));
    }
  }

  @override
  void dispose() {
    for (final c in [
      _usernameCtrl, _emailCtrl, _passwordCtrl,
      _fullNameCtrl, _phoneCtrl, _addressCtrl, _birthDateCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_birthDateCtrl.text) ??
          DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _birthDateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
        _dirty.add('birthDate');
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      if (!_isEdit) {
        controller.register(
          username : _usernameCtrl.text,
          email    : _emailCtrl.text,
          password : _passwordCtrl.text,
          fullName : _fullNameCtrl.text,
          phone    : _phoneCtrl.text,
          birthDate: _birthDateCtrl.text,
          gender   : _selectedGender,
          address  : _addressCtrl.text,
        ).then((_) => controller.fetchAllUsers());
      } else {
        controller.updateUserAccount(
          id       : userToEdit!.id,
          username : _usernameCtrl.text,
          email    : _emailCtrl.text,
          fullName : _fullNameCtrl.text,
          phone    : _phoneCtrl.text,
          birthDate: _birthDateCtrl.text,
          gender   : _selectedGender,
          address  : _addressCtrl.text,
          password : _passwordCtrl.text.isNotEmpty
              ? _passwordCtrl.text
              : null,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Obx(() => Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar preview
                        _buildAvatarPreview(),
                        const SizedBox(height: 28),

                        // ── Informasi Akun ─────────────────────────────
                        _sectionLabel('Informasi Akun'),
                        const SizedBox(height: 12),
                        _buildCard([
                          _buildField(
                            ctrl: _usernameCtrl,
                            label: 'Username',
                            icon: Icons.alternate_email_rounded,
                            fieldKey: 'username',
                          ),
                          _divider(),
                          _buildField(
                            ctrl: _emailCtrl,
                            label: 'Email',
                            icon: Icons.email_rounded,
                            fieldKey: 'email',
                            keyboard: TextInputType.emailAddress,
                          ),
                          _divider(),
                          _buildPasswordField(),
                        ]),

                        const SizedBox(height: 20),

                        // ── Data Personal ──────────────────────────────
                        _sectionLabel('Data Personal'),
                        const SizedBox(height: 12),
                        _buildCard([
                          _buildField(
                            ctrl: _fullNameCtrl,
                            label: 'Nama Lengkap',
                            icon: Icons.person_rounded,
                            fieldKey: 'fullName',
                          ),
                          _divider(),
                          _buildField(
                            ctrl: _phoneCtrl,
                            label: 'Nomor Telepon',
                            icon: Icons.phone_rounded,
                            fieldKey: 'phone',
                            keyboard: TextInputType.phone,
                          ),
                          _divider(),
                          _buildGenderPicker(),
                          _divider(),
                          _buildDateField(),
                          _divider(),
                          _buildField(
                            ctrl: _addressCtrl,
                            label: 'Alamat',
                            icon: Icons.location_on_rounded,
                            fieldKey: 'address',
                            maxLines: 3,
                          ),
                        ]),

                        const SizedBox(height: 32),
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
                if (controller.isLoading.value)
                  Container(
                    color: Colors.black.withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  ),
              ],
            )),
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
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEdit ? 'Edit Pengguna' : 'Tambah Pengguna',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      _isEdit
                          ? 'Perbarui data akun pengguna'
                          : 'Buat akun pengguna baru',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
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

  // ── Avatar preview ─────────────────────────────────────────────────────────
  Widget _buildAvatarPreview() {
    return Center(
      child: Container(
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
          child: Text(
            _fullNameCtrl.text.isNotEmpty
                ? _fullNameCtrl.text[0].toUpperCase()
                : (_isEdit ? (userToEdit!.fullName.isNotEmpty
                    ? userToEdit!.fullName[0].toUpperCase()
                    : '?') : '+'),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textGrey,
          letterSpacing: 0.8,
        ),
      );

  Widget _buildCard(List<Widget> children) => Container(
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

  Widget _divider() => Divider(
        height: 1, indent: 56, endIndent: 16,
        color: AppColors.secondary,
      );

  // ── Text field dalam card ──────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required String fieldKey,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final isDirty = _dirty.contains(fieldKey);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500,
            color: AppColors.textMain),
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
              decoration: BoxDecoration(
                color: isDirty
                    ? AppColors.primary.withOpacity(0.12)
                    : AppColors.secondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: isDirty ? AppColors.primary : AppColors.textGrey,
                  size: 17),
            ),
          ),
          suffixIcon: isDirty
              ? const Icon(Icons.circle, color: AppColors.primary, size: 8)
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
        validator: validator ??
            (v) => v == null || v.isEmpty ? '$label wajib diisi' : null,
      ),
    );
  }

  // ── Password field ─────────────────────────────────────────────────────────
  Widget _buildPasswordField() {
    final isDirty = _dirty.contains('password');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500,
            color: AppColors.textMain),
        decoration: InputDecoration(
          labelText: _isEdit
              ? 'Password Baru (kosongkan jika tidak diubah)'
              : 'Password',
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
              child: Icon(Icons.lock_rounded,
                  color: isDirty ? AppColors.primary : AppColors.textGrey,
                  size: 17),
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: AppColors.textGrey,
              size: 18,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
        validator: (v) => (!_isEdit && (v == null || v.isEmpty))
            ? 'Password wajib diisi'
            : null,
      ),
    );
  }

  // ── Gender picker ──────────────────────────────────────────────────────────
  Widget _buildGenderPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _dirty.contains('gender')
                  ? AppColors.primary.withOpacity(0.12)
                  : AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.wc_rounded,
                color: _dirty.contains('gender')
                    ? AppColors.primary
                    : AppColors.textGrey,
                size: 17),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jenis Kelamin',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textGrey)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _genderChip('L', 'Laki-laki',
                        Icons.male_rounded)),
                    const SizedBox(width: 10),
                    Expanded(child: _genderChip('P', 'Perempuan',
                        Icons.female_rounded)),
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
        _dirty.add('gender');
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.secondary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : AppColors.textGrey,
                size: 16),
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

  // ── Date picker field ──────────────────────────────────────────────────────
  Widget _buildDateField() {
    final isDirty = _dirty.contains('birthDate');
    return GestureDetector(
      onTap: _selectDate,
      child: AbsorbPointer(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextFormField(
            controller: _birthDateCtrl,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500,
                color: AppColors.textMain),
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
                  child: Icon(Icons.calendar_month_rounded,
                      color: isDirty ? AppColors.primary : AppColors.textGrey,
                      size: 17),
                ),
              ),
              suffixIcon: const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textGrey, size: 20),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
      ),
    );
  }

  // ── Tombol simpan adaptive ─────────────────────────────────────────────────
  Widget _buildSaveButton() {
    final hasChanges = _dirty.isNotEmpty || !_isEdit;
    return Obx(() {
      final isLoading = controller.isLoading.value;
      return GestureDetector(
        onTap: (isLoading || (!hasChanges && _isEdit)) ? null : _save,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: (hasChanges || !_isEdit) && !isLoading
                ? AppColors.primary
                : AppColors.textGrey.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
            boxShadow: (hasChanges || !_isEdit) && !isLoading
                ? [BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 14, offset: const Offset(0, 5))]
                : [],
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isEdit
                            ? Icons.check_rounded
                            : Icons.person_add_rounded,
                        color: Colors.white, size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isEdit ? 'Simpan Perubahan' : 'Daftarkan Pengguna',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      );
    });
  }
}
