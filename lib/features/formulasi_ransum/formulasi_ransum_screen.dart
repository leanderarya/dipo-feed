import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_comparison_bar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/bahan_pakan.dart';
import '../../data/models/campuran_pakan_item.dart';
import '../../data/models/profil_sapi.dart';
import '../../data/sources/bahan_pakan_repository.dart';
import 'logic/hasil_formulasi.dart';
import 'logic/perhitungan_formulasi.dart';

class FormulasiRansumScreen extends StatefulWidget {
  const FormulasiRansumScreen({super.key});

  @override
  State<FormulasiRansumScreen> createState() => _FormulasiRansumScreenState();
}

class _FormulasiRansumScreenState extends State<FormulasiRansumScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _beratBadanController = TextEditingController();
  final TextEditingController _produksiSusuController = TextEditingController();
  final TextEditingController _lemakSusuController = TextEditingController();
  final TextEditingController _paritasController = TextEditingController();
  final TextEditingController _bulanBuntingController = TextEditingController();
  final TextEditingController _bulanLaktasiController = TextEditingController();

  StatusKebuntingan _statusKebuntingan = StatusKebuntingan.tidakBunting;
  TahapLaktasi? _tahapLaktasiTerdeteksi;

  final BahanPakanRepository _repository = BahanPakanRepository();
  List<BahanPakan> _semuaBahan = [];
  final List<CampuranPakanItem> _bahanTerpilih = [];

  bool _isLoadingBahan = true;
  HasilFormulasi? _hasilFormulasi;

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
      setState(() {
        _semuaBahan = _repository.data;
        _isLoadingBahan = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat bahan pakan: $e')),
      );
      setState(() {
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

  String _labelTahapLaktasi(TahapLaktasi tahap) {
    switch (tahap) {
      case TahapLaktasi.dara:
        return 'Dara';
      case TahapLaktasi.keringKandang:
        return 'Kering kandang';
      case TahapLaktasi.laktasi0Sampai4Minggu:
        return 'Awal laktasi 0–4 minggu';
      case TahapLaktasi.laktasi4Sampai16Minggu:
        return 'Awal laktasi 4–16 minggu';
      case TahapLaktasi.laktasi16Sampai30Minggu:
        return 'Tengah laktasi 16–30 minggu';
      case TahapLaktasi.laktasi30Sampai44Minggu:
        return 'Akhir laktasi 30–44 minggu';
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


  void _tambahBahan() {
    if (_semuaBahan.isEmpty) return;

    final bahanSudahDipakai = _bahanTerpilih.map((e) => e.bahan.id).toSet();

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
      _bahanTerpilih.add(
        CampuranPakanItem(
          bahan: bahanBaru!,
          jumlahKg: 0,
          hargaPerKg: bahanBaru.hargaDefault,
        ),
      );
    });
  }

  void _hapusBahan(int index) {
    setState(() {
      _bahanTerpilih.removeAt(index);
    });
  }

  void _ubahBahan(int index, BahanPakan bahanBaru) {
    final sudahDipakai = _bahanTerpilih.asMap().entries.any((entry) {
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
      _bahanTerpilih[index] = _bahanTerpilih[index].copyWith(
        bahan: bahanBaru,
        hargaPerKg: bahanBaru.hargaDefault,
      );
    });
  }

  double _parseDouble(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  int _parseInt(String value) {
    return int.tryParse(value) ?? 0;
  }

  void _hitungFormulasi() {
    if (!_formKey.currentState!.validate()) return;

    if (_bahanTerpilih.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih minimal 1 bahan pakan terlebih dahulu.'),
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

    final hasil = PerhitunganFormulasi.hitungFormulasi(
      sapi: profil,
      daftarBahanTerpilih: _bahanTerpilih,
    );

    setState(() {
      _tahapLaktasiTerdeteksi = tahapLaktasi;
      _hasilFormulasi = hasil;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: const AppHeader(
        title: 'Simulator Ransum',
        heading: 'Formulasi Ransum',
        subtitle: 'Simulasikan komposisi bahan pakan untuk mencapai target nutrisi harian.',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoadingBahan ? null : _tambahBahan,
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Bahan'),
      ),
      body: _isLoadingBahan
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  AppCard(
                    title: 'Profil Sapi',
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _beratBadanController,
                                  label: 'Berat Badan (kg)',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  controller: _produksiSusuController,
                                  label: 'Produksi Susu (L)',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _lemakSusuController,
                                  label: 'Lemak Susu (%)',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTextField(
                                  controller: _paritasController,
                                  label: 'Paritas',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _bulanLaktasiController,
                            label: 'Bulan Laktasi',
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<StatusKebuntingan>(
                            initialValue: _statusKebuntingan,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: 'Status Kebuntingan'),
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
                                });
                              }
                            },
                          ),
                          if (_statusKebuntingan == StatusKebuntingan.bunting) ...[
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _bulanBuntingController,
                              label: 'Bulan Bunting',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Pilihan Bahan Pakan', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  if (_bahanTerpilih.isEmpty)
                    _buildEmptyBahanState()
                  else
                    ...List.generate(
                      _bahanTerpilih.length,
                      (index) => _buildKartuBahan(index, _bahanTerpilih[index]),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _hitungFormulasi,
                      child: const Text('Simulasikan Ransum'),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_hasilFormulasi != null) ...[
                    _buildHasilHeader(),
                    const SizedBox(height: 16),
                    _buildKartuRekomendasi(),
                    const SizedBox(height: 16),
                    _buildKartuEvaluasiNutrisi(),
                  ],
                ],
              ),
            ),
    );
  }


  Widget _buildHasilHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hasil Simulasi', style: Theme.of(context).textTheme.titleLarge),
        if (_tahapLaktasiTerdeteksi != null) ...[
          const SizedBox(height: 4),
          _buildTahapLaktasiInfo(),
        ],
      ],
    );
  }

  Widget _buildKartuBahan(int index, CampuranPakanItem item) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<BahanPakan>(
              initialValue: item.bahan,
              isExpanded: true,
              decoration: const InputDecoration(border: InputBorder.none),
              items: _semuaBahan.map((bahan) {
                return DropdownMenuItem<BahanPakan>(
                  value: bahan,
                  child: Text(bahan.nama, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) _ubahBahan(index, value);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _hapusBahan(index),
            icon: const Icon(Icons.close, color: AppColors.errorRed, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBahanState() {
    return const AppCard(
      padding: EdgeInsets.all(24),
      child: Center(
        child: Text(
          'Belum ada bahan pakan yang dipilih.',
          style: TextStyle(color: AppColors.textGrey, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildKartuRekomendasi() {
    final hasil = _hasilFormulasi!;
    double totalBiaya = 0;
    for (var rec in hasil.rekomendasiPakan) {
      final bahanOriginal = _bahanTerpilih.firstWhere((e) => e.bahan.nama == rec.namaBahan);
      totalBiaya += rec.jumlahKg * bahanOriginal.hargaPerKg;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          title: 'Komposisi Ransum Ideal',
          child: Column(
            children: [
              ...hasil.rekomendasiPakan.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.namaBahan, style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('${item.jumlahKg.toStringAsFixed(2)} kg/hari'),
                      ],
                    ),
                  )),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Biaya /hari', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'Rp ${totalBiaya.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildResultMetric('Hijauan', '${hasil.persentaseHijauan.toStringAsFixed(0)}%'),
              _buildResultMetric('Konsentrat', '${hasil.persentaseKonsentrat.toStringAsFixed(0)}%'),
              _buildResultMetric('BK Ransum', '${hasil.bkRansumPersen.toStringAsFixed(1)}%'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
      ],
    );
  }

  Widget _buildKartuEvaluasiNutrisi() {
    final ev = _hasilFormulasi!.evaluasi;

    return AppCard(
      title: 'Evaluasi Nutrisi',
      child: Column(
        children: [
          AppComparisonBar(
            label: 'BK (kg)',
            current: ev.bk.pemberian,
            limit: ev.bk.kebutuhan,
          ),
          const SizedBox(height: 16),
          AppComparisonBar(
            label: 'PK (kg)',
            current: ev.protein.pemberian,
            limit: ev.protein.kebutuhan,
          ),
          const SizedBox(height: 16),
          AppComparisonBar(
            label: 'TDN (kg)',
            current: ev.tdn.pemberian,
            limit: ev.tdn.kebutuhan,
          ),
        ],
      ),
    );
  }

  Widget _buildTahapLaktasiInfo() {
    return Text(
      'Tahap Laktasi: ${_labelTahapLaktasi(_tahapLaktasiTerdeteksi!)}',
      style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
    );

  }
}