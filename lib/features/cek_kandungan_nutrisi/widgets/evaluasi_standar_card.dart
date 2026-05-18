import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../logic/evaluasi_standar_nutrien.dart';

class EvaluasiStandarCard extends StatelessWidget {
  final HasilEvaluasiStandarNutrien evaluasi;
  final double totalBeratKg;
  final double totalBiaya;

  const EvaluasiStandarCard({
    super.key,
    required this.evaluasi,
    required this.totalBeratKg,
    required this.totalBiaya,
  });

  @override
  Widget build(BuildContext context) {
    EvaluasiStandarNutrienItem? lemakItem;
    for (final item in evaluasi.items) {
      if (item.label == 'Lemak') {
        lemakItem = item;
        break;
      }
    }
    final showLemakWarning = lemakItem != null &&
        lemakItem.status == StatusStandarNutrien.berlebih;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.expertPurple.withValues(alpha: 0.08), // Soft brand purple background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.expertPurple.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useSingleColumnSummary = constraints.maxWidth < 280;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          'Hasil Kandungan Pakan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.expertPurple,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Standar: ${evaluasi.standar.nama}',
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
              if (useSingleColumnSummary) ...[
                _buildMiniInfo(
                  'Berat Campuran',
                  '${totalBeratKg.toStringAsFixed(2)} kg',
                ),
                const SizedBox(height: 10),
                _buildMiniInfo(
                  'Total Biaya',
                  'Rp ${totalBiaya.toStringAsFixed(0)}',
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniInfo(
                        'Berat Campuran',
                        '${totalBeratKg.toStringAsFixed(2)} kg',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildMiniInfo(
                        'Total Biaya',
                        'Rp ${totalBiaya.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              _buildNutrientPanel(
                items: evaluasi.items,
                showLemakWarning: showLemakWarning,
              ),
              if (evaluasi.kesimpulan.isNotEmpty) ...[
                const SizedBox(height: 20),
                // Kesimpulan Standar Nutrisi with high-intensity solid purple background
                Container(
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
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Kesimpulan Analisis',
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
                        evaluasi.kesimpulan,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Pure white background for pop contrast
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.expertPurple.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.expertPurple.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.expertPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientPanel({
    required List<EvaluasiStandarNutrienItem> items,
    required bool showLemakWarning,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Pure white background for pop contrast
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.expertPurple.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _buildItem(
              items[i],
              showInlineWarning:
                  showLemakWarning && items[i].label == 'Lemak',
            ),
            if (i != items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade100,
                indent: 12,
                endIndent: 12,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(
    EvaluasiStandarNutrienItem item, {
    bool showInlineWarning = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Standar: ${item.standar}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
                if (showInlineWarning) ...[
                  const SizedBox(height: 4),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFC97A18),
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Melebihi batas aman 7%',
                          style: TextStyle(
                            color: Color(0xFF9A5D11),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 74, maxWidth: 112),
            child: Text(
              '${item.hasil.toStringAsFixed(2)}%',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
