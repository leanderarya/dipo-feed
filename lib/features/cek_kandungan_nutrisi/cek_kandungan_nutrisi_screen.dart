import 'package:flutter/material.dart';

import '../../core/widgets/app_card.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/bahan_pakan.dart';
import '../../data/models/campuran_pakan_item.dart';
import '../../data/models/hasil_pakan_terpilih.dart';
import '../../data/sources/bahan_pakan_repository.dart';
import '../master_pakan/master_pakan_screen.dart';
import 'logic/perhitungan_nutrisi.dart';

class CekKandunganNutrisiScreen extends StatefulWidget {
  final bool modePilihUntukEvaluasi;

  const CekKandunganNutrisiScreen({
    super.key,
    this.modePilihUntukEvaluasi = false,
  });

  @override
  State<CekKandunganNutrisiScreen> createState() =>
      _CekKandunganNutrisiScreenState();
}

class _CekKandunganNutrisiScreenState extends State<CekKandunganNutrisiScreen> {
  final BahanPakanRepository _repository = BahanPakanRepository();

  List<BahanPakan> _semuaBahan = [];
  final List<CampuranPakanItem> _campuran = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _muatBahanPakan();
  }

  Future<void> _muatBahanPakan() async {
    try {
      await _repository.initialize();
      setState(() {
        _semuaBahan = _repository.dataAktif;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat bahan pakan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _bukaManajemenMaster() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MasterPakanScreen()),
    );
    await _repository.refresh();
    if (!mounted) return;
    setState(() {
      _semuaBahan = _repository.dataAktif;
    });
  }

  void _tambahBahan() {
    if (_semuaBahan.isEmpty) return;

    final bahanSudahDipakai = _campuran.map((item) => item.bahan.id).toSet();
    BahanPakan? bahanBaru;
    for (final bahan in _semuaBahan) {
      if (!bahanSudahDipakai.contains(bahan.id)) {
        bahanBaru = bahan;
        break;
      }
    }

    if (bahanBaru == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua bahan pakan aktif sudah ditambahkan.')),
      );
      return;
    }

    setState(() {
      _campuran.add(
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
      _campuran.removeAt(index);
    });
  }

  void _ubahBahan(int index, BahanPakan bahanBaru) {
    final sudahDipakaiOlehItemLain = _campuran.asMap().entries.any((entry) {
      return entry.key != index && entry.value.bahan.id == bahanBaru.id;
    });

    if (sudahDipakaiOlehItemLain) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bahan tersebut sudah dipilih pada item lain.')),
      );
      return;
    }

    setState(() {
      _campuran[index] = _campuran[index].copyWith(
        bahan: bahanBaru,
        hargaPerKg: bahanBaru.hargaDefault,
      );
    });
  }

  void _ubahJumlahKg(int index, String value) {
    final jumlah = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    setState(() {
      _campuran[index].jumlahKg = jumlah < 0 ? 0 : jumlah;
    });
  }

  void _ubahHargaPerKg(int index, String value) {
    final harga = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    setState(() {
      _campuran[index].hargaPerKg = harga < 0 ? 0 : harga;
    });
  }

  void _gunakanUntukEvaluasi(HasilPerhitunganNutrisi hasil) {
    if (hasil.totalBerat <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total campuran pakan harus lebih dari 0 kg.')),
      );
      return;
    }

    final payload = HasilPakanTerpilih(
      totalBeratKg: hasil.totalBerat,
      bkPersen: hasil.bk,
      proteinPersen: hasil.protein,
      tdnPersen: hasil.tdn,
      me: hasil.me,
    );

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final hasil = PerhitunganNutrisi.hitungSemua(_campuran);

    return Scaffold(
      backgroundColor: AppColors.backgroundKrem,
      appBar: AppHeader(
        title: 'Cek Kandungan Nutrisi',
        heading: 'Simulasi Campuran',
        subtitle: 'Cek kandungan nutrisi dari campuran pakan buatan Anda sendiri.',
        actions: [
          IconButton(
            tooltip: 'Master Pakan',
            onPressed: _isLoading ? null : _bukaManajemenMaster,
            icon: const Icon(Icons.inventory_2_outlined, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(hasil)),
      bottomNavigationBar: widget.modePilihUntukEvaluasi && _campuran.isNotEmpty && hasil.totalBerat > 0
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () => _gunakanUntukEvaluasi(hasil),
                child: const Text('Gunakan untuk Evaluasi'),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(HasilPerhitunganNutrisi hasil) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      children: [
        if (_campuran.isEmpty)
          _buildEmptyState()
        else ...[
          const Text(
            'Bahan Campuran',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._campuran.asMap().entries.map((entry) => _buildKartuBahan(entry.key, entry.value)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _tambahBahan,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('Tambah Bahan Pakan'),
          ),
          const SizedBox(height: 32),
          _buildKartuHasil(hasil),
        ],
      ],
    );
  }


  Widget _buildEmptyState() {
    return AppCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.feed_outlined, size: 48, color: AppColors.textGrey),
          const SizedBox(height: 16),
          const Text(
            'Belum ada bahan campuran.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Klik tombol di bawah untuk mulai menyusun pakan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _tambahBahan,
            icon: const Icon(Icons.add),
            label: const Text('Susun Pakan'),
          ),
        ],
      ),
    );
  }

  Widget _buildKartuBahan(int index, CampuranPakanItem item) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<BahanPakan>(
                  initialValue: item.bahan,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Bahan Pakan',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  items: _semuaBahan.map((bahan) {
                    return DropdownMenuItem<BahanPakan>(
                      value: bahan,
                      child: Text(bahan.nama, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (v) => v != null ? _ubahBahan(index, v) : null,
                ),
              ),
              IconButton(
                onPressed: () => _hapusBahan(index),
                icon: const Icon(Icons.close, color: AppColors.errorRed, size: 20),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  initialValue: item.jumlahKg == 0 ? '' : item.jumlahKg.toStringAsFixed(2),
                  label: 'Jumlah (kg)',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _ubahJumlahKg(index, v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  initialValue: item.hargaPerKg == 0 ? '' : item.hargaPerKg.toStringAsFixed(0),
                  label: 'Harga/kg',
                  prefixText: 'Rp ',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _ubahHargaPerKg(index, v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKartuHasil(HasilPerhitunganNutrisi hasil) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Analisis Kandungan Nutrisi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              _buildResultRow('Bahan Kering (BK)', '${hasil.bk.toStringAsFixed(2)}%'),
              _buildResultRow('Protein Kasar (PK)', '${hasil.protein.toStringAsFixed(2)}%'),
              _buildResultRow('TDN', '${hasil.tdn.toStringAsFixed(2)}%'),
              _buildResultRow('Berat Campuran', '${hasil.totalBerat.toStringAsFixed(2)} kg'),
              const Divider(height: 32),
              _buildResultRow(
                'Total Biaya',
                'Rp ${hasil.totalBiaya.toStringAsFixed(0)}',
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textGrey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? AppColors.primaryGreen : null,
              fontSize: isBold ? 16 : null,
            ),
          ),
        ],
      ),
    );
  }
}
