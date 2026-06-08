import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/symptoms.dart';
import '../../controllers/diagnosis_controller.dart';

// ─── Page ─────────────────────────────────────────────────────────────────────
class DiagnosisCorePage extends GetView<DiagnosisController> {
  const DiagnosisCorePage({super.key});

  // Minimal 5 gejala, selebihnya makin baik (skala terbuka)
  static const int _minSymptoms = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildGuidance(),
          _buildSearchBar(),
          Expanded(
            child: _buildCategoryList(),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  // ── Header dengan gradient + progress bar ──────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pemeriksaan Gejala',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Obx(() {
                    if (controller.selectedSymptoms.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      onTap: _showResetDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded,
                                color: AppColors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Reset',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.only(left: 32),
                child: Text(
                  'Pilih gejala yang Anda rasakan saat ini',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final count = controller.selectedSymptoms.length;
                // Skala: 0–5 = wajib minimum, >5 = makin baik
                // Progress: 100% dicapai di 5 gejala, lebih = tetap penuh
                final pct = (count / _minSymptoms).clamp(0.0, 1.0);
                final bool cukup = count >= _minSymptoms;
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          cukup ? const Color(0xFF66BB6A) : AppColors.white,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$count gejala dipilih',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          cukup
                              ? count == _minSymptoms
                                  ? 'Minimum tercapai ✓'
                                  : 'Sangat baik! +${count - _minSymptoms} ekstra'
                              : '${_minSymptoms - count} lagi untuk minimum',
                          style: TextStyle(
                            color: cukup
                                ? const Color(0xFFA5D6A7)
                                : Colors.white70,
                            fontSize: 11,
                            fontWeight: cukup
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reset Dialog ───────────────────────────────────────────────────────────
  void _showResetDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.refresh_rounded,
                    color: AppColors.error, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reset Semua Pilihan?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Obx(() => Text(
                    '${controller.selectedSymptoms.length} gejala yang sudah dipilih akan dihapus.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                      height: 1.5,
                    ),
                  )),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.secondary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        controller.resetSymptoms();
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700),
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

  // ── Panduan Pengisian ──────────────────────────────────────────────────────
  Widget _buildGuidance() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline_rounded,
                    color: AppColors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Panduan Pengisian',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _guidanceItem(
            Icons.check_circle_outline_rounded,
            'Pilih minimal 5 gejala',
            'untuk memulai proses diagnosa',
            AppColors.primary,
          ),
          const SizedBox(height: 6),
          _guidanceItem(
            Icons.trending_up_rounded,
            'Semakin banyak semakin akurat',
            'lebih banyak gejala = hasil diagnosa lebih tepat',
            const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 6),
          _guidanceItem(
            Icons.category_outlined,
            'Gejala dikelompokkan per kategori',
            'tap kategori untuk melihat dan memilih gejala',
            const Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }

  Widget _guidanceItem(
      IconData icon, String title, String desc, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$title — ',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                    height: 1.5,
                  ),
                ),
                TextSpan(
                  text: desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secondary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (v) => controller.searchQuery.value = v.trim(),
          style: const TextStyle(fontSize: 14, color: AppColors.textMain),
          decoration: const InputDecoration(
            hintText: 'Cari gejala...',
            hintStyle: TextStyle(color: AppColors.textGrey, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded,
                color: AppColors.primary, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  // ── Daftar Kategori ────────────────────────────────────────────────────────
  Widget _buildCategoryList() {
    return Obx(() {
      final query = controller.searchQuery.value.toLowerCase();
      final filtered = symptomCategories.map((cat) {
        if (query.isEmpty) return cat;
        final filteredSymptoms = cat.symptoms
            .where((s) =>
                s['name']!.toLowerCase().contains(query) ||
                s['code']!.toLowerCase().contains(query))
            .toList();
        return SymptomCategory(
          id: cat.id,
          title: cat.title,
          subtitle: cat.subtitle,
          icon: cat.icon,
          accentColor: cat.accentColor,
          symptoms: filteredSymptoms,
        );
      }).where((cat) => cat.symptoms.isNotEmpty).toList();

      if (filtered.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 48, color: AppColors.textGrey.withOpacity(0.4)),
              const SizedBox(height: 12),
              const Text(
                'Tidak ada gejala yang cocok',
                style: TextStyle(color: AppColors.textGrey, fontSize: 14),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: filtered.length,
        itemBuilder: (ctx, i) => _CategoryCard(
          category: filtered[i],
          controller: controller,
          forceOpen: query.isNotEmpty,
        ),
      );
    });
  }

  // ── Tombol Diagnosa (bottom sticky) ───────────────────────────────────────
  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.secondary,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Obx(() {
          final count = controller.selectedSymptoms.length;
          final isLoading = controller.isLoading.value;
          return SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    count > 0 ? AppColors.primary : AppColors.textGrey.withOpacity(0.3),
                foregroundColor: AppColors.white,
                elevation: count > 0 ? 4 : 0,
                shadowColor: AppColors.primary.withOpacity(0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: (count > 0 && !isLoading)
                  ? () => controller.performDiagnosis()
                  : null,
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: AppColors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.biotech_rounded, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'PROSES DIAGNOSA',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              letterSpacing: 0.5),
                        ),
                        if (count > 0) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Category Card Widget ─────────────────────────────────────────────────────
class _CategoryCard extends StatefulWidget {
  final SymptomCategory category;
  final DiagnosisController controller;
  final bool forceOpen;

  const _CategoryCard({
    required this.category,
    required this.controller,
    required this.forceOpen,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _animCtrl;
  late Animation<double> _chevronTurn;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _chevronTurn = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
    _expandAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    _isOpen ? _animCtrl.forward() : _animCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final effectiveOpen = widget.forceOpen || _isOpen;

    // Sync animation when forceOpen changes
    if (widget.forceOpen && !_animCtrl.isCompleted) {
      _animCtrl.forward();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cat.accentColor.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          if (effectiveOpen)
            BoxShadow(
              color: cat.accentColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: widget.forceOpen ? null : _toggle,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon box
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cat.accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cat.icon, color: cat.accentColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cat.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cat.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Selected badge
                  Obx(() {
                    final selectedCount = cat.symptoms
                        .where((s) =>
                            widget.controller.selectedSymptoms
                                .contains(s['code']))
                        .length;
                    return selectedCount > 0
                        ? Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cat.accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '$selectedCount dipilih',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: cat.accentColor,
                              ),
                            ),
                          )
                        : const SizedBox.shrink();
                  }),
                  // Chevron
                  if (!widget.forceOpen)
                    RotationTransition(
                      turns: _chevronTurn,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: cat.accentColor,
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Expandable Symptom List ───────────────────────────────────────
          SizeTransition(
            sizeFactor: widget.forceOpen
                ? const AlwaysStoppedAnimation(1)
                : _expandAnim,
            child: Column(
              children: [
                Divider(
                  height: 1,
                  color: cat.accentColor.withOpacity(0.12),
                  indent: 14,
                  endIndent: 14,
                ),
                ...cat.symptoms.map((sym) => _SymptomTile(
                      symptom: sym,
                      accentColor: cat.accentColor,
                      controller: widget.controller,
                    )),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Symptom Tile ─────────────────────────────────────────────────────────────
class _SymptomTile extends StatelessWidget {
  final Map<String, String> symptom;
  final Color accentColor;
  final DiagnosisController controller;

  const _SymptomTile({
    required this.symptom,
    required this.accentColor,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected =
          controller.selectedSymptoms.contains(symptom['code']);
      return InkWell(
        onTap: () => controller.toggleSymptom(symptom['code']!),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Custom checkbox
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? accentColor
                        : AppColors.textGrey.withOpacity(0.4),
                    width: 1.8,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.white, size: 15)
                    : null,
              ),
              const SizedBox(width: 12),
              // Name
              Expanded(
                child: Text(
                  symptom['name']!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? AppColors.textMain : AppColors.textMain,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Code badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  symptom['code']!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
