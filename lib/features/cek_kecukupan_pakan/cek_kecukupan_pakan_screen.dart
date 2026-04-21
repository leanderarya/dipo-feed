import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_comparison_bar.dart';
import '../../data/models/bahan_pakan.dart';
import '../../data/models/campuran_pakan_item.dart';
import '../../data/models/hasil_kecukupan_pakan.dart';
import '../../data/models/profil_sapi.dart';
import '../../data/sources/bahan_pakan_repository.dart';
import '../cek_kandungan_nutrisi/logic/perhitungan_nutrisi.dart';
import 'logic/perhitungan_kecukupan_pakan.dart';

class CekKecukupanPakanScreen extends StatefulWidget {
  const CekKecukupanPakanScreen({super.key});

  @override
  State<CekKecukupanPakanScreen> createState() =>
      _CekKecukupanPakanScreenState();
}

class _CekKecukupanPakanScreenState extends State<CekKecukupanPakanScreen> {
  final _formKey = GlobalKey<FormState>();
  final BahanPakanRepository _repository = BahanPakanRepository();

  final TextEditingController _beratBadanController = TextEditingController();
  final TextEditingController _produksiSusuController = TextEditingController();
  final TextEditingController _lemakSusuController = TextEditingController();
  final TextEditingController _paritasController = TextEditingController();
  final TextEditingController _bulanBuntingController = TextEditingController();
  final TextEditingController _bulanLaktasiController = TextEditingController();

  StatusKebuntingan _statusKebuntingan = StatusKebuntingan.tidakBunting;

  List<BahanPakan> _semuaBahan = [];
  final List<CampuranPakanItem> _pemberianPakan = [];

  bool _isLoadingBahan = true;
  String? _errorBahan;

  HasilEvaluasiKecukupan? _hasilEvaluasi;
  HasilPerhitunganNutrisi? _hasilCampuranPakan;

  @override
  void initState() {
    super.initState();
    _muatBahanPakan();
  }

  @override
  void dispose() {
    _beratBadanController.dispose();
    _produksiSusuController.dispose();
    _lemakSusuController.dispose();
    _paritasController.dispose();
    _bulanBuntingController.dispose();
    _bulanLaktasiController.dispose();
    super.dispose();
  }

  Future<void> _muatBahanPakan() async {
    try {
      await _repository.initialize();
      final data = _repository.dataAktif;
      setState(() {
        _semuaBahan = data;
        _isLoadingBahan = false;
      });
    } catch (e) {
      setState(() {
        _errorBahan = 'Gagal memuat bahan pakan: $e';
        _isLoadingBahan = false;
      });
    }
  }

  TahapLaktasi _konversiBulanLaktasiKeTahap(int bulanLaktasi) {
    final minggu = bulanLaktasi * 4;

    if (minggu <= 4) {
      return TahapLaktasi.laktasi0Sampai4Minggu;
    } else if (minggu <= 16) {
      return TahapLaktasi.laktasi4Sampai16Minggu;
    } else if (minggu <= 30) {
      return TahapLaktasi.laktasi16Sampai30Minggu;
    } else if (minggu <= 44) {
      return TahapLaktasi.laktasi30Sampai44Minggu;
    } else {
      return TahapLaktasi.keringKandang;
    }
  }

  String _labelStatusKebuntingan(StatusKebuntingan status) {
    switch (status) {
      case StatusKebuntingan.tidakBunting:
        return 'Tidak bunting';
      case StatusKebuntingan.bunting:
        return 'Bunting';
    }
  }


  void _tambahBahanPakan() {
    if (_semuaBahan.isEmpty) return;

    final bahanSudahDipakai = _pemberianPakan.map((e) => e.bahan.id).toSet();

    BahanPakan? bahanBaru;
    for (final bahan in _semuaBahan) {
      if (!bahanSudahDipakai.contains(bahan.id)) {
        bahanBaru = bahan;
        break;
      }
    }

    if (bahanBaru == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua bahan pakan aktif sudah ditambahkan.'),
        ),
      );
      return;
    }

    setState(() {
      _pemberianPakan.add(
        CampuranPakanItem(
          bahan: bahanBaru!,
          jumlahKg: 0,
          hargaPerKg: bahanBaru.hargaDefault,
        ),
      );
    });
  }

  void _hapusBahanPakan(int index) {
    setState(() {
      _pemberianPakan.removeAt(index);
    });
  }

  void _ubahBahanPakan(int index, BahanPakan bahanBaru) {
    final sudahDipakai = _pemberianPakan.asMap().entries.any((entry) {
      return entry.key != index && entry.value.bahan.id == bahanBaru.id;
    });

    if (sudahDipakai) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bahan tersebut sudah dipilih pada item lain.'),
        ),
      );
      return;
    }

    setState(() {
      _pemberianPakan[index] = _pemberianPakan[index].copyWith(
        bahan: bahanBaru,
        hargaPerKg: bahanBaru.hargaDefault,
      );
    });
  }

  void _ubahJumlahPakan(int index, String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    setState(() {
      _pemberianPakan[index].jumlahKg = parsed < 0 ? 0 : parsed;
    });
  }

  void _hitungEvaluasi() {
    if (!_formKey.currentState!.validate()) return;

    if (_pemberianPakan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal satu bahan pakan terlebih dahulu.'),
        ),
      );
      return;
    }

    final totalBerat = PerhitunganNutrisi.hitungTotalBerat(_pemberianPakan);
    if (totalBerat <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total pemberian pakan harus lebih dari 0 kg.'),
        ),
      );
      return;
    }

    final bulanLaktasi = _parseInt(_bulanLaktasiController.text);
    final tahapLaktasi = _konversiBulanLaktasiKeTahap(bulanLaktasi);

    final profil = ProfilSapi(
      beratBadan: _parseDouble(_beratBadanController.text),
      produksiSusu: _parseDouble(_produksiSusuController.text),
      persenLemakSusu: _parseDouble(_lemakSusuController.text),
      paritas: _parseInt(_paritasController.text),
      tahapLaktasi: tahapLaktasi,
      statusKebuntingan: _statusKebuntingan,
      bulanBunting: _statusKebuntingan == StatusKebuntingan.bunting
          ? _parseInt(_bulanBuntingController.text)
          : 0,
    );

    final hasilPakan = PerhitunganNutrisi.hitungSemua(_pemberianPakan);

    final bkPemberianKg = hasilPakan.totalBerat * (hasilPakan.bk / 100);
    final proteinPemberianKg =
        hasilPakan.totalBerat * (hasilPakan.protein / 100);
    final tdnPemberianKg = hasilPakan.totalBerat * (hasilPakan.tdn / 100);
    final mePemberian = hasilPakan.totalBerat * hasilPakan.me;

    final evaluasi = PerhitunganKecukupanPakan.evaluasiManual(
      sapi: profil,
      bkPemberianKg: bkPemberianKg,
      proteinPemberianKg: proteinPemberianKg,
      tdnPemberianKg: tdnPemberianKg,
      mePemberian: mePemberian,
    );

    setState(() {
      _hasilCampuranPakan = hasilPakan;
      _hasilEvaluasi = evaluasi;
    });
  }

  double _parseDouble(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  int _parseInt(String value) {
    return int.tryParse(value) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: const AppHeader(
        title: 'Cek Kecukupan',
        heading: 'Evaluasi Nutrisi',
        subtitle: 'Masukkan data sapi dan pemberian pakan harian untuk melihat kecukupannya.',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoadingBahan ? null : _tambahBahanPakan,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Bahan Pakan'),
      ),
      body: _isLoadingBahan
          ? const Center(child: CircularProgressIndicator())
          : _errorBahan != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_errorBahan!, textAlign: TextAlign.center),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            _buildFormInput(),
                            const SizedBox(height: 24),
                            if (_hasilEvaluasi != null) _buildKartuHasilEvaluasi(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }


  Widget _buildFormInput() {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Sapi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _beratBadanController,
              label: 'Berat Badan',
              suffix: 'kg',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _produksiSusuController,
              label: 'Produksi Susu',
              suffix: 'liter/hari',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _lemakSusuController,
                    label: 'Lemak Susu',
                    suffix: '%',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _paritasController,
                    label: 'Paritas (Beranak)',
                    suffix: 'ke',
                    isInteger: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _bulanLaktasiController,
                    label: 'Bulan Laktasi',
                    suffix: 'bulan',
                    isInteger: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Hamil',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<StatusKebuntingan>(
                        initialValue: _statusKebuntingan,
                        items: StatusKebuntingan.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(_labelStatusKebuntingan(status)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _statusKebuntingan = v;
                              if (_statusKebuntingan == StatusKebuntingan.tidakBunting) {
                                _bulanBuntingController.clear();
                              }
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_statusKebuntingan == StatusKebuntingan.bunting) ...[
              const SizedBox(height: 12),
              AppTextField(
                controller: _bulanBuntingController,
                label: 'Bulan Kebuntingan',
                suffix: 'bulan',
                isInteger: true,
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(),
            ),
            Text(
              'Pemberian Pakan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_pemberianPakan.isEmpty)
              _buildEmptyPakanState()
            else
              ...List.generate(
                _pemberianPakan.length,
                (index) => _buildKartuPakan(index, _pemberianPakan[index]),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _hitungEvaluasi,
              child: const Text('Hitung Evaluasi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPakanState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.eco_outlined, size: 48, color: AppColors.primaryGreen.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'Pakan belum ditambahkan',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textLight),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Klik tombol + di bawah untuk menambah bahan pakan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }


  Widget _buildKartuPakan(int index, CampuranPakanItem item) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Bahan ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _hapusBahanPakan(index),
                icon: const Icon(Icons.close, size: 20, color: AppColors.errorRed),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<BahanPakan>(
            initialValue: item.bahan,
            isExpanded: true,
            items: _semuaBahan.map((bahan) {
              return DropdownMenuItem<BahanPakan>(
                value: bahan,
                child: Text(bahan.nama, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) _ubahBahanPakan(index, value);
            },
          ),
          const SizedBox(height: 12),
          AppTextField(
            initialValue: item.jumlahKg == 0 ? '' : item.jumlahKg.toStringAsFixed(2),
            label: 'Jumlah (kg)',
            onChanged: (value) => _ubahJumlahPakan(index, value),
          ),
        ],
      ),
    );
  }


  Widget _buildKartuHasilEvaluasi() {
    if (_hasilEvaluasi == null || _hasilCampuranPakan == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hasil Evaluasi',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              AppComparisonBar(
                label: 'Bahan Kering (BK)',
                current: _hasilEvaluasi!.bk.pemberian,
                limit: _hasilEvaluasi!.bk.kebutuhan,
                unit: 'kg',
              ),
              const SizedBox(height: 20),
              AppComparisonBar(
                label: 'Protein Kasar (PK)',
                current: _hasilEvaluasi!.protein.pemberian,
                limit: _hasilEvaluasi!.protein.kebutuhan,
                unit: 'kg',
              ),
              const SizedBox(height: 20),
              AppComparisonBar(
                label: 'Total Digestible Nutrients (TDN)',
                current: _hasilEvaluasi!.tdn.pemberian,
                limit: _hasilEvaluasi!.tdn.kebutuhan,
                unit: 'kg',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primaryGreen),
                  SizedBox(width: 8),
                  Text(
                    'Kesimpulan Umum',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryGreen),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _hasilEvaluasi!.kesimpulanUmum,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
