import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';
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
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.rule_folder_outlined,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hasil Kandungan Pakan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Standar: ${evaluasi.standar.nama}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 14),
          ...evaluasi.items.map(_buildItem),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rangkuman',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                ...evaluasi.narasi.map(
                  (narasi) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      narasi,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                if (evaluasi.narasi.isNotEmpty) const SizedBox(height: 6),
                Text(
                  evaluasi.kesimpulan,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniInfo(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(EvaluasiStandarNutrienItem item) {
    final visual = _statusVisual(item.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(visual.icon, color: visual.foreground, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.hasil.toStringAsFixed(2)}%  •  ${item.standar}',
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _statusLabel(item.status),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: visual.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusVisual _statusVisual(StatusStandarNutrien status) {
    switch (status) {
      case StatusStandarNutrien.kurang:
        return _StatusVisual(
          background: const Color(0xFFFFE5E5),
          foreground: AppColors.errorRed,
          icon: Icons.south_rounded,
        );
      case StatusStandarNutrien.sesuai:
        return _StatusVisual(
          background: const Color(0xFFE6F4EA),
          foreground: const Color(0xFF1B8A5A),
          icon: Icons.check_circle_outline,
        );
      case StatusStandarNutrien.berlebih:
        return _StatusVisual(
          background: const Color(0xFFFFF0E1),
          foreground: const Color(0xFFC97A18),
          icon: Icons.north_rounded,
        );
    }
  }

  String _statusLabel(StatusStandarNutrien status) {
    switch (status) {
      case StatusStandarNutrien.kurang:
        return 'Kurang';
      case StatusStandarNutrien.sesuai:
        return 'Sesuai';
      case StatusStandarNutrien.berlebih:
        return 'Berlebih';
    }
  }
}

class _StatusVisual {
  final Color background;
  final Color foreground;
  final IconData icon;

  const _StatusVisual({
    required this.background,
    required this.foreground,
    required this.icon,
  });
}
