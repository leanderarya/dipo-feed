import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/indonesian_number_formatter.dart';
import '../../../data/models/fisiologi_sapi.dart';
import '../logic/evaluasi_kecukupan_nutrien.dart';

class EvaluasiKecukupanCard extends StatelessWidget {
  final HasilEvaluasiKecukupanNutrien hasil;

  const EvaluasiKecukupanCard({super.key, required this.hasil});

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
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
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
                      'Standar Kebutuhan: ${_labelFisiologi(hasil.fisiologi)}',
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
                for (var i = 0; i < hasil.items.length; i++) ...[
                  _buildNutrientComparisonRow(context, hasil.items[i]),
                  if (i != hasil.items.length - 1)
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
          const SizedBox(height: 20),

          // Kesimpulan Umum Card
          _buildKesimpulanCard(),
        ],
      ),
    );
  }

  Widget _buildNutrientComparisonRow(
    BuildContext context,
    EvaluasiKecukupanItem item,
  ) {
    final (color, statusLabel) = switch (item.status) {
      StatusKecukupanNutrien.pas => (AppColors.statusPas, 'Pas'),
      StatusKecukupanNutrien.berlebih => (AppColors.statusBerlebih, 'Berlebih'),
      StatusKecukupanNutrien.kurang => (AppColors.statusKurang, 'Kurang'),
    };

    final percentageFactor = item.kebutuhan > 0
        ? (item.pemberian / item.kebutuhan).clamp(0.0, 1.2)
        : 0.0;

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
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${item.nama})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                'Kebutuhan: ${_format(item.kebutuhan)} ${item.satuan}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress & Target Visual Bar
          Stack(
            children: [
              Container(
                height: 10,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (percentageFactor / 1.2).clamp(0.0, 1.0),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              // Target 100% threshold line
              if (item.kebutuhan > 0)
                Positioned(
                  left: (MediaQuery.of(context).size.width - 76) * (1.0 / 1.2),
                  child: Container(
                    height: 10,
                    width: 2,
                    color: AppColors.textDark.withValues(alpha: 0.35),
                  ),
                ),
            ],
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
              fontSize: 11,
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
        'Kurang ${_format(butuh)} ${item.satuan}',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    if (item.status == StatusKecukupanNutrien.berlebih) {
      final lebih = (item.pemberian - item.kebutuhan).abs();
      return Text(
        'Kelebihan ${_format(lebih)} ${item.satuan}',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Text(
      'Sesuai kebutuhan',
      style: TextStyle(
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.w600,
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
            hasil.kesimpulanUmum,
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
