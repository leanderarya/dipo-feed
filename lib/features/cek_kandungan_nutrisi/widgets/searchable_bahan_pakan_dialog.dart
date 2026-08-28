import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/indonesian_number_formatter.dart';
import '../../../data/models/bahan_pakan.dart';

class SearchableBahanPakanDialog extends StatefulWidget {
  final List<BahanPakan> semuaBahan;
  final Set<int> bahanTerpilihIds;
  final BahanPakan? bahanSaatIni;

  const SearchableBahanPakanDialog({
    super.key,
    required this.semuaBahan,
    required this.bahanTerpilihIds,
    this.bahanSaatIni,
  });

  static Future<BahanPakan?> show({
    required BuildContext context,
    required List<BahanPakan> semuaBahan,
    required Set<int> bahanTerpilihIds,
    BahanPakan? bahanSaatIni,
  }) {
    return showModalBottomSheet<BahanPakan>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchableBahanPakanDialog(
        semuaBahan: semuaBahan,
        bahanTerpilihIds: bahanTerpilihIds,
        bahanSaatIni: bahanSaatIni,
      ),
    );
  }

  @override
  State<SearchableBahanPakanDialog> createState() =>
      _SearchableBahanPakanDialogState();
}

class _SearchableBahanPakanDialogState
    extends State<SearchableBahanPakanDialog> {
  late List<BahanPakan> _filteredBahan;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredBahan = List.from(widget.semuaBahan);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBahan(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredBahan = List.from(widget.semuaBahan);
      } else {
        _filteredBahan = widget.semuaBahan
            .where(
              (b) =>
                  b.nama.toLowerCase().contains(query.trim().toLowerCase()) ||
                  b.kategori.toLowerCase().contains(query.trim().toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.backgroundKrem,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                const Text(
                  'Pilih Bahan Pakan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _filterBahan,
              decoration: InputDecoration(
                hintText: 'Cari nama atau kategori pakan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterBahan('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: _filteredBahan.isEmpty
                ? const Center(
                    child: Text(
                      'Bahan pakan tidak ditemukan.',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredBahan.length,
                    itemBuilder: (context, index) {
                      final bahan = _filteredBahan[index];
                      final isSelectedCurrent =
                          widget.bahanSaatIni?.id == bahan.id;
                      final isAlreadyUsed =
                          widget.bahanTerpilihIds.contains(bahan.id) &&
                              !isSelectedCurrent;

                      return ListTile(
                        enabled: !isAlreadyUsed,
                        title: Text(
                          bahan.nama,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isAlreadyUsed
                                ? AppColors.textGrey
                                : AppColors.textDark,
                          ),
                        ),
                        subtitle: Text(
                          'Kategori: ${bahan.kategori} • BK: ${IndonesianNumberFormatter.format(bahan.bk, decimals: 1)}%',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: isSelectedCurrent
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.secondaryGreen,
                              )
                            : isAlreadyUsed
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Sudah Dipilih',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textGrey,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.chevron_right, size: 18),
                        onTap: () {
                          if (isAlreadyUsed) {
                            AppToast.showWarning(
                              context,
                              'Bahan pakan "${bahan.nama}" sudah dipilih dalam campuran.',
                            );
                            return;
                          }
                          Navigator.pop(context, bahan);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
