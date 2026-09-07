import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/indonesian_number_formatter.dart';
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

  /// Format angka ke format ribuan Indonesia (titik sebagai pemisah ribuan)
  String _formatRibuan(double value) =>
      IndonesianNumberFormatter.format(value, decimals: 0);

  /// Hitung biaya per kg campuran
  double get _biayaPerKg {
    if (totalBeratKg <= 0) return 0;
    return totalBiaya / totalBeratKg;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.expertPurple.withValues(alpha: 0.08),
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
                          'Kandungan Campuran Pakan',
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
                            color: AppColors.expertPurple.withValues(
                              alpha: 0.8,
                            ),
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
                _buildBeratCampuranInfo(),
                const SizedBox(height: 10),
                _buildBiayaPakanInfo(),
              ] else
                Row(
                  children: [
                    Expanded(child: _buildBeratCampuranInfo()),
                    const SizedBox(width: 10),
                    Expanded(child: _buildBiayaPakanInfo()),
                  ],
                ),
              const SizedBox(height: 16),
              _buildNutrientPanel(items: evaluasi.items),
              const SizedBox(height: 12),
              _buildInfoNoteBK(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBeratCampuranInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            'Berat Campuran',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.expertPurple.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${IndonesianNumberFormatter.format(totalBeratKg, decimals: 2)} kg',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.expertPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '(berat segar / as fed)',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.expertPurple.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiayaPakanInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            'Biaya Pakan',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.expertPurple.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Rp ${_formatRibuan(_biayaPerKg)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.expertPurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '/kg campuran',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.expertPurple.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Total: ${CurrencyFormatter.formatRupiah(totalBiaya)}',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.expertPurple.withValues(alpha: 0.7),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoNoteBK() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: AppColors.expertPurple.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Perhitungan berdasarkan Bahan Kering',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.expertPurple.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientPanel({
    required List<EvaluasiStandarNutrienItem> items,
  }) {
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
          for (var i = 0; i < items.length; i++) ...[
            _buildItem(items[i]),
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

  Widget _buildItem(EvaluasiStandarNutrienItem item) {
    final isBk = item.label == 'BK';
    final isLemak = item.label == 'Lemak';
    final showStandar = !isBk;
    final includeWarning = isLemak && item.hasil >= 7;

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
                if (showStandar) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Standar: ${item.standar}',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
                if (includeWarning) ...[
                  const SizedBox(height: 4),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Terlalu Tinggi',
                          style: TextStyle(
                            color: Colors.red,
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
              '${IndonesianNumberFormatter.format(item.hasil, decimals: 2)}%',
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
