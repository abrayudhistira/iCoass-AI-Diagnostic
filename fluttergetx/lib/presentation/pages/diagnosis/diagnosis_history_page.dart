import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
import 'package:flutter/material.dart';
import 'package:fluttergetx/core/constants/colors.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../../../domain/entities/diagnosis_entity.dart';
import '../../controllers/diagnosis_controller.dart';

/// Warna confidence badge berdasarkan nilai persentase
Color _confidenceColor(double pct) {
  if (pct >= 75) return AppColors.success;
  if (pct >= 50) return AppColors.warning;
  return AppColors.error;
}

/// Label tekstual confidence
String _confidenceLabel(double pct) {
  if (pct >= 75) return 'Tinggi';
  if (pct >= 50) return 'Sedang';
  return 'Rendah';
}

// ─── Page ─────────────────────────────────────────────────────────────────────
class DiagnosisHistoryPage extends GetView<DiagnosisController> {
  const DiagnosisHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Konten utama
          Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return _buildLoadingState();
                  }
                  if (controller.historyList.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildHistoryList();
                }),
              ),
            ],
          ),

          // Draggable Banner - Pastikan ini child TERAKHIR
          const _ExpandableDiagnosisBanner(),
        ],
      ),
    );
  }

  // ── Header gradient (sama dengan DiagnosisCorePage) ────────────────────────
  Widget _buildHeader() {
    final bottomNavRoutes = [
      '/home',
      '/artikel',
      '/diagnosis-history',
      '/profile',
    ];
    final showBackButton = !bottomNavRoutes.contains(Get.previousRoute);
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
                    onTap: () => Get.toNamed('/home'),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Riwayat Diagnosa',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Badge jumlah riwayat
                  Obx(() {
                    final count = controller.historyList.length;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$count riwayat',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
                  'Hasil pemeriksaan sebelumnya',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return CustomRefreshIndicator(
      onRefresh: () => controller.fetchHistory(), // sesuaikan nama method-nya
      builder: (context, child, indicatorController) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            if (!indicatorController.isIdle)
              Positioned(
                top: 25.0 * indicatorController.value,
                child: SizedBox(
                  height: 60,
                  child: Lottie.asset('assets/lottie/loading_animation.json'),
                ),
              ),
            Transform.translate(
              offset: Offset(0, 80.0 * indicatorController.value),
              child: child,
            ),
          ],
        );
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: controller.historyList.length,
        itemBuilder: (context, index) {
          final reversedIndex = controller.historyList.length - 1 - index;
          final data = controller.historyList[reversedIndex];
          return _HistoryCard(
            item: data,
            index: reversedIndex,
            onTap: () => _showDetailSheet(context, data),
          );
        },
      ),
    );
  }

  // ── Loading skeleton ───────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: 4,
      itemBuilder: (_, __) => const _SkeletonCard(),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada riwayat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hasil diagnosa akan muncul di sini\nsetelah kamu melakukan pemeriksaan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => Get.toNamed('/diagnosis-core'),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Mulai Diagnosa',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAB Diagnosa Baru ──────────────────────────────────────────────────────
  // Widget _buildFAB() {
  //   return Obx(() {
  //     if (controller.historyList.isEmpty) return const SizedBox.shrink();
  //     return FloatingActionButton.extended(
  //       onPressed: () => Get.toNamed('/diagnosis-core'),
  //       label: const Text(
  //         'Diagnosa Baru',
  //         style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
  //       ),
  //       icon: const Icon(Icons.add_rounded),
  //       backgroundColor: AppColors.primary,
  //       foregroundColor: AppColors.white,
  //       elevation: 6,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //     );
  //   });
  // }

  Widget _buildFAB() {
    return Obx(() {
      if (controller.historyList.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: 70), // 👈 Naikkan ini
        child: FloatingActionButton.extended(
          onPressed: () => Get.toNamed('/diagnosis-core'),
          label: const Text(
            'Diagnosa Baru',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          icon: const Icon(Icons.add_rounded),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    });
  }

  // ── Bottom Sheet detail diagnosa ───────────────────────────────────────────
  void _showDetailSheet(BuildContext context, DiagnosisResult diagnosis) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailBottomSheet(diagnosis: diagnosis),
    );
  }
}

// ─── History Card ─────────────────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final DiagnosisResult item;
  final int index;
  final VoidCallback onTap;

  const _HistoryCard({
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final confidenceVal = double.tryParse(item.confidence.toString()) ?? 0.0;
    final color = _confidenceColor(confidenceVal);
    final label = _confidenceLabel(confidenceVal);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.10),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nomor urut
              // Container(
              //   width: 40,
              //   height: 40,
              //   decoration: BoxDecoration(
              //     color: AppColors.primary.withOpacity(0.10),
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: Center(
              //     child: Text(
              //       '${index + 1}',
              //       style: const TextStyle(
              //         fontSize: 14,
              //         fontWeight: FontWeight.w700,
              //         color: AppColors.primary,
              //       ),
              //     ),
              //   ),
              // ),
              const SizedBox(width: 12),
              // Info diagnosa
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.mainDiagnosis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Confidence bar
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: confidenceVal / 100,
                              backgroundColor: color.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.confidence}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Detail count
                    Text(
                      '${item.details.length} kemungkinan penyakit teranalisa',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge confidence + chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textGrey.withOpacity(0.5),
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Detail Bottom Sheet ──────────────────────────────────────────────────────
class _DetailBottomSheet extends StatelessWidget {
  final DiagnosisResult diagnosis;

  const _DetailBottomSheet({required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    // Sort detail dari probabilitas tertinggi
    final sortedDetails = [...diagnosis.details]
      ..sort((a, b) => b.probability.compareTo(a.probability));

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textGrey.withOpacity(0.25),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          // Scrollable content
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header sheet
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.biotech_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detail Hasil Diagnosa',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMain,
                              ),
                            ),
                            Text(
                              'Distribusi probabilitas Naive Bayes',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Diagnosa utama highlight
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.08),
                          AppColors.primary.withOpacity(0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.20),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Diagnosa Utama',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          diagnosis.mainDiagnosis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _ConfidenceChip(
                              value:
                                  double.tryParse(
                                    diagnosis.confidence.toString(),
                                  ) ??
                                  0.0,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Penjelasan AI Gemini
                  const Row(
                    children: [
                      Icon(
                        Icons.assistant_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Penjelasan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<String>(
                    future: Get.find<DiagnosisController>().getExplanation(
                      diagnosis,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        );
                      }

                      final explanationText =
                          snapshot.data ?? 'Gagal memuat penjelasan.';
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.15),
                          ),
                        ),
                        child: Text(
                          explanationText,
                          textAlign: TextAlign.justify,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMain,
                            height: 1.5,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Judul distribusi
                  const Row(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Distribusi Probabilitas',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Daftar probabilitas
                  ...sortedDetails.asMap().entries.map((entry) {
                    final i = entry.key;
                    final detail = entry.value;
                    final pct =
                        double.tryParse(detail.probability.toString()) ?? 0.0;
                    final color = _confidenceColor(pct);
                    final isTop = i == 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isTop
                            ? color.withOpacity(0.06)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isTop
                              ? color.withOpacity(0.25)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  detail.diseaseName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isTop
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: AppColors.textMain,
                                  ),
                                ),
                              ),
                              if (isTop)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    'Tertinggi',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ),
                              Text(
                                '${detail.probability}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: pct / 100,
                              backgroundColor: color.withOpacity(0.12),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 12),

                  // Tombol tutup
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Confidence Chip ──────────────────────────────────────────────────────────
class _ConfidenceChip extends StatelessWidget {
  final double value;
  const _ConfidenceChip({required this.value});

  @override
  Widget build(BuildContext context) {
    final color = _confidenceColor(value);
    final label = _confidenceLabel(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 5),
          Text(
            'Keyakinan $label • ${value.round()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton Loading Card ────────────────────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _shimmerBox(40, 40, radius: 12),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(12, double.infinity),
                  const SizedBox(height: 8),
                  _shimmerBox(8, 160),
                  const SizedBox(height: 8),
                  _shimmerBox(8, 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double height, double width, {double radius = 6}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(_anim.value),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ExpandableDiagnosisBanner extends StatefulWidget {
  const _ExpandableDiagnosisBanner({super.key});

  @override
  State<_ExpandableDiagnosisBanner> createState() =>
      _ExpandableDiagnosisBannerState();
}

class _ExpandableDiagnosisBannerState extends State<_ExpandableDiagnosisBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool isExpanded = false;
  Offset? _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_position == null) {
      final size = MediaQuery.of(context).size;
      setState(() {
        _position = Offset(size.width - 90, size.height * 0.45);
      });
    }
  }

  void _toggleExpand() {
    setState(() {
      isExpanded = !isExpanded;
      isExpanded ? _controller.forward() : _controller.reverse();
    });
  }

  void _navigateToDiagnosis() {
    Get.toNamed('/diagnosis-core');
    Future.delayed(const Duration(milliseconds: 300), () {
      if (isExpanded && mounted) _toggleExpand();
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final size = MediaQuery.of(context).size;
    final current = _position!;

    setState(() {
      _position = Offset(
        (current.dx + details.delta.dx).clamp(16.0, size.width - 80),
        (current.dy + details.delta.dy).clamp(
          120.0, // ← Batas atas (tidak masuk header biru)
          size.height - 160.0, // ← Batas bawah (hindari bottom nav)
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_position == null) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;
    final placement = _getBannerPlacement(size);

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: GestureDetector(
        onPanUpdate: _onDragUpdate,
        onTap: _toggleExpand,
        child: AbsorbPointer(
          // ← Fix gesture tembus
          absorbing: false,
          child: SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Banner
                // === BANNER GAMBAR ===
                AnimatedBuilder(
                  animation: _animation,
                  builder: (_, __) {
                    if (_animation.value == 0) return const SizedBox.shrink();

                    final screenWidth = MediaQuery.of(context).size.width;
                    final isRightSide = _position!.dx > screenWidth * 0.5;

                    // Posisi banner
                    final bannerWidth =
                        260.0; // sesuaikan dengan ukuran gambar kamu
                    double bannerLeft = isRightSide
                        ? -(bannerWidth - 64) // geser ke kiri kalau di kanan
                        : 0.0;

                    // Agar tidak keluar layar di sebelah kiri
                    if (isRightSide && bannerLeft + _position!.dx < 10) {
                      bannerLeft = 10 - _position!.dx;
                    }

                    return Positioned(
                      top:
                          _position!.dy >
                              MediaQuery.of(context).size.height * 0.55
                          ? -165 // banner ke atas
                          : 78, // banner ke bawah
                      left: bannerLeft,
                      child: Transform.scale(
                        scale: _animation.value,
                        alignment: isRightSide
                            ? Alignment.bottomRight
                            : Alignment.bottomLeft,
                        child: Opacity(
                          opacity: _animation.value,
                          child: GestureDetector(
                            onTap: _navigateToDiagnosis,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 50,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  'assets/images/banner.png', // ← GANTI DENGAN PATH KAMU
                                  width: bannerWidth,
                                  height: 120, // sesuaikan tinggi gambar
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // AnimatedBuilder(
                //   animation: _animation,
                //   builder: (_, __) {
                //     if (_animation.value == 0) return const SizedBox.shrink();

                //     final bannerWidth = 240.0;
                //     final bannerHeight = 54.0;
                //     final gap = 12.0;

                //     final isBottomArea = _position!.dy > size.height * 0.6;

                //     final bannerTop = isBottomArea
                //         ? -(bannerHeight + gap)
                //         : 70.0;

                //     final bannerLeft = _position!.dx > size.width * 0.5
                //         ? -(bannerWidth - 64)
                //         : 0.0;

                //     return Positioned(
                //       top: bannerTop,
                //       left: bannerLeft,
                //       child: Transform.scale(
                //         scale: _animation.value,
                //         alignment: isBottomArea
                //             ? Alignment.bottomRight
                //             : Alignment.topRight,
                //         child: Opacity(
                //           opacity: _animation.value,
                //           child: GestureDetector(
                //             onTap: _navigateToDiagnosis,
                //             behavior: HitTestBehavior.opaque,
                //             child: Container(
                //               width: bannerWidth,
                //               padding: const EdgeInsets.symmetric(
                //                 horizontal: 18,
                //                 vertical: 14,
                //               ),
                //               decoration: BoxDecoration(
                //                 color: AppColors.primary,
                //                 borderRadius: BorderRadius.circular(16),
                //                 boxShadow: [
                //                   BoxShadow(
                //                     color: AppColors.primary.withOpacity(0.5),
                //                     blurRadius: 20,
                //                     offset: const Offset(0, 8),
                //                   ),
                //                 ],
                //               ),
                //               child: const Row(
                //                 mainAxisSize: MainAxisSize.min,
                //                 children: [
                //                   Expanded(
                //                     child: Text(
                //                       'Ayo Diagnosa Sekarang',
                //                       style: TextStyle(
                //                         color: Colors.white,
                //                         fontWeight: FontWeight.w700,
                //                         fontSize: 14.5,
                //                       ),
                //                     ),
                //                   ),
                //                   Icon(
                //                     Icons.arrow_forward_rounded,
                //                     color: Colors.white,
                //                     size: 22,
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ),
                //         ),
                //       ),
                //     );
                //   },
                // ),

                // FAB
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    // color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(
                          255,
                          180,
                          206,
                          228,
                        ).withOpacity(0.6),
                        blurRadius: 18,
                        offset: const Offset(2, 8),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/diagnosa-now.png', // ← GANTI DENGAN PATH ASSET KAMU
                      fit: BoxFit.cover,
                      width: 32,
                      height: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _BannerPlacement _getBannerPlacement(Size size) {
    final pos = _position!;
    return _BannerPlacement(
      isBottom: pos.dy > size.height * 0.6,
      isLeft: pos.dx < size.width * 0.5,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Helper
class _BannerPlacement {
  final bool isBottom;
  final bool isLeft;
  const _BannerPlacement({required this.isBottom, required this.isLeft});
}
