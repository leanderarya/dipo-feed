import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/indonesian_number_formatter.dart';
import '../../../data/models/fisiologi_sapi.dart';
import '../logic/evaluasi_kecukupan_nutrien.dart';

class EvaluasiKecukupanCard extends StatefulWidget {
  final HasilEvaluasiKecukupanNutrien hasil;
  final bool initialExpanded;

  const EvaluasiKecukupanCard({
    super.key,
    required this.hasil,
    this.initialExpanded = false,
  });

  @override
  State<EvaluasiKecukupanCard> createState() => _EvaluasiKecukupanCardState();
}

class _EvaluasiKecukupanCardState extends State<EvaluasiKecukupanCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  String _format(double val) =>
      IndonesianNumberFormatter.format(val, decimals: 2);

  String _labelFisiologi(FisiologiSapi fisiologi) {
    switch (fisiologi) {
      case FisiologiSapi.dara:
        return 'Dara (NRC 1978)';
      case FisiologiSapi.laktasi:
        return 'Laktasi (NRC 1988)';
      case FisiologiSapi.keringKandang:
        return 'Kering Kandang';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.expertPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.expertPurple.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: AppColors.expertPurple,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hasil Evaluasi Nutrisi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.expertPurple,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Standar Kebutuhan: ${_labelFisiologi(widget.hasil.fisiologi)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.expertPurple.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dual-Mode Content with AnimatedCrossFade
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _buildCompactContent(),
            secondChild: _buildExpandedContent(),
          ),

          const SizedBox(height: 12),

          // Toggle Mode Button
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? 'Tutup Detail' : 'Lihat Detail',
                      style: const TextStyle(
                        color: AppColors.expertPurple,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.expertPurple,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // COMPACT MODE CONTENT
  // ==========================================
  Widget _buildCompactContent() {
    final primaryItems = [
      widget.hasil.bk,
      widget.hasil.protein,
      widget.hasil.tdn,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.expertPurple.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < primaryItems.length; i++) ...[
            _buildCompactNutrientRow(primaryItems[i]),
            if (i != primaryItems.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade100,
                indent: 14,
                endIndent: 14,
              ),
          ],
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade100,
            indent: 14,
            endIndent: 14,
          ),
          _buildCompactMineralDisabledRow(),
        ],
      ),
    );
  }

  Widget _buildCompactNutrientRow(EvaluasiKecukupanItem item) {
    final (color, statusLabel) = switch (item.status) {
      StatusKecukupanNutrien.pas => (AppColors.statusPas, 'Pas'),
      StatusKecukupanNutrien.berlebih => (AppColors.statusBerlebih, 'Berlebih'),
      StatusKecukupanNutrien.kurang => (AppColors.statusKurang, 'Kurang'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    item.singkatan,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '(${item.nama})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(color, statusLabel),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${_format(item.pemberian)} / ${_format(item.kebutuhan)} ${item.satuan}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              _buildSelisihText(item, color),
            ],
          ),
          const SizedBox(height: 8),
          StackedNutrientProgressBar(
            kebutuhan: item.kebutuhan,
            pemberian: item.pemberian,
            segmen: item.segmen,
            fallbackColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMineralDisabledRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Ca & P (Mineral)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textLight,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Data mineral master pakan belum tersedia',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text(
              'Belum ada data',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EXPANDED MODE CONTENT
  // ==========================================
  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comparison Panel inside structured white card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.expertPurple.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < widget.hasil.items.length; i++) ...[
                _buildExpandedNutrientRow(widget.hasil.items[i]),
                if (i != widget.hasil.items.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade100,
                    indent: 14,
                    endIndent: 14,
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Note Section for Ca & P
        _buildInfoNoteCaP(),
        const SizedBox(height: 16),

        // Kesimpulan Umum Card
        _buildKesimpulanCard(),
      ],
    );
  }

  Widget _buildExpandedNutrientRow(EvaluasiKecukupanItem item) {
    final (color, statusLabel) = switch (item.status) {
      StatusKecukupanNutrien.pas => (AppColors.statusPas, 'Pas'),
      StatusKecukupanNutrien.berlebih => (AppColors.statusBerlebih, 'Berlebih'),
      StatusKecukupanNutrien.kurang => (AppColors.statusKurang, 'Kurang'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title, Abbreviation, and Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    item.singkatan,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '(${item.nama})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(color, statusLabel),
            ],
          ),
          const SizedBox(height: 6),

          // Values: Pemberian / Kebutuhan (kg/g)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pemberian: ${_format(item.pemberian)} ${item.satuan}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Kebutuhan: ${_format(item.kebutuhan)} ${item.satuan}',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stacked Progress Bar
          StackedNutrientProgressBar(
            kebutuhan: item.kebutuhan,
            pemberian: item.pemberian,
            segmen: item.segmen,
            fallbackColor: color,
          ),
          const SizedBox(height: 4),

          // Difference description
          Align(
            alignment: Alignment.centerRight,
            child: _buildSelisihText(item, color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelisihText(EvaluasiKecukupanItem item, Color color) {
    if (item.status == StatusKecukupanNutrien.kurang) {
      final butuh = (item.kebutuhan - item.pemberian).abs();
      return Text(
        'butuh ${_format(butuh)} ${item.satuan}',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    if (item.status == StatusKecukupanNutrien.berlebih) {
      final lebih = (item.pemberian - item.kebutuhan).abs();
      return Text(
        'lebih ${_format(lebih)} ${item.satuan}',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Text(
      'Sesuai kebutuhan',
      style: TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildInfoNoteCaP() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: AppColors.expertPurple.withValues(alpha: 0.65),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Catatan: Nilai pemberian Ca dan P saat ini masih 0 karena data kandungan mineral pada master bahan pakan belum tersedia.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.expertPurple.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKesimpulanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.expertPurple,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.expertPurple.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Kesimpulan Umum',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 15,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.hasil.kesimpulanUmum,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.95),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class StackedNutrientProgressBar extends StatelessWidget {
  final double kebutuhan;
  final double pemberian;
  final List<SegmenKontribusiNutrien> segmen;
  final Color fallbackColor;

  const StackedNutrientProgressBar({
    super.key,
    required this.kebutuhan,
    required this.pemberian,
    required this.segmen,
    required this.fallbackColor,
  });

  @override
  Widget build(BuildContext context) {
    final baseMax = kebutuhan > 0 ? kebutuhan * 1.2 : 1.0;
    final maxScale = (pemberian > baseMax) ? pemberian * 1.05 : baseMax;
    final targetFraction =
        kebutuhan > 0 ? (kebutuhan / maxScale).clamp(0.0, 1.0) : 0.0;
    final targetFillFactor =
        pemberian > 0 ? (pemberian / maxScale).clamp(0.0, 1.0) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Background bar
            Container(
              height: 11,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200, width: 0.5),
              ),
            ),
            // Animated Segmented items or fallback
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: targetFillFactor),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, animatedFill, child) {
                final animatedWidth = animatedFill * totalWidth;
                if (segmen.isNotEmpty && pemberian > 0) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 11,
                      width: animatedWidth,
                      child: Row(
                        children: segmen.map((s) {
                          if (s.nilaiKg <= 0) return const SizedBox.shrink();
                          final segmentFraction =
                              (s.nilaiKg / pemberian).clamp(0.0, 1.0);
                          return Expanded(
                            flex:
                                (segmentFraction * 1000).round().clamp(1, 1000),
                            child: Container(
                              color: s.warna,
                              height: 11,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  );
                } else if (pemberian > 0) {
                  return Container(
                    height: 11,
                    width: animatedWidth,
                    decoration: BoxDecoration(
                      color: fallbackColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            // Target 100% threshold line
            if (kebutuhan > 0)
              Positioned(
                left: (targetFraction * totalWidth).clamp(0.0, totalWidth - 2),
                child: Container(
                  height: 15,
                  width: 2.5,
                  decoration: BoxDecoration(
                    color: AppColors.textDark.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
