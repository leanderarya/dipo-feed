import 'package:flutter/material.dart';

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

  KebutuhanNutrisiSapi? _hasilKebutuhan;
  HasilEvaluasiKecukupan? _hasilEvaluasi;
  HasilPerhitunganNutrisi? _hasilCampuranPakan;
  TahapLaktasi? _tahapLaktasiTerdeteksi;

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

  Color _warnaStatus(String status) {
    switch (status) {
      case 'Kurang':
        return Colors.red;
      case 'Berlebih':
        return Colors.green;
      default:
        return Colors.black87;
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

    final kebutuhan = PerhitunganKecukupanPakan.hitungKebutuhan(profil);
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
      _tahapLaktasiTerdeteksi = tahapLaktasi;
      _hasilKebutuhan = kebutuhan;
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
      appBar: AppBar(
        title: const Text('Cek Kecukupan Pakan'),
        centerTitle: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoadingBahan ? null : _tambahBahanPakan,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Pakan'),
      ),
      body: SafeArea(
        child: _isLoadingBahan
            ? const Center(child: CircularProgressIndicator())
            : _errorBahan != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_errorBahan!, textAlign: TextAlign.center),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildFormInput(),
                  const SizedBox(height: 16),
                  if (_tahapLaktasiTerdeteksi != null) _buildTahapLaktasiInfo(),
                  if (_tahapLaktasiTerdeteksi != null)
                    const SizedBox(height: 16),
                  _buildKartuHasilKebutuhan(),
                  const SizedBox(height: 16),
                  _buildKartuHasilEvaluasi(),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rule_folder_outlined, size: 22),
              SizedBox(width: 8),
              Text(
                'Evaluasi Kecukupan Pakan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Isi data sapi dan pilih bahan pakan yang diberikan. Sistem akan menghitung total nutrisi pakan lalu membandingkannya dengan kebutuhan sapi.',
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelWithInfo(String label, String message) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 6),
        Tooltip(
          message: message,
          triggerMode: TooltipTriggerMode.tap,
          showDuration: const Duration(seconds: 3),
          child: Icon(
            Icons.info_outline,
            size: 18,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildFormInput() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Sapi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 14),
              _buildNumberField(
                controller: _beratBadanController,
                label: 'Berat badan',
                suffix: 'kg',
              ),
              const SizedBox(height: 12),
              _buildLabelWithInfo(
                'Produksi susu',
                'Diisi jumlah produksi susu rata-rata per hari dalam satuan liter per ekor.',
              ),
              const SizedBox(height: 8),
              _buildNumberField(
                controller: _produksiSusuController,
                label: 'Produksi susu',
                suffix: 'liter/ekor/hari',
              ),
              const SizedBox(height: 12),
              _buildLabelWithInfo(
                'Lemak susu',
                'Diisi sesuai dengan pengetahuan peternak. Misal 3 - 3,5%.',
              ),
              const SizedBox(height: 8),
              _buildNumberField(
                controller: _lemakSusuController,
                label: 'Lemak susu',
                suffix: '%',
              ),
              const SizedBox(height: 12),
              _buildLabelWithInfo(
                'Periode laktasi',
                'Jumlah berapa kali sapi sudah beranak. Contoh: jika sapi sudah melahirkan 2 kali, maka isi 2.',
              ),
              const SizedBox(height: 8),
              _buildNumberField(
                controller: _paritasController,
                label: 'Periode laktasi',
                suffix: 'ke',
                isInteger: true,
              ),
              const SizedBox(height: 12),
              _buildLabelWithInfo(
                'Bulan laktasi',
                'Diisi jumlah bulan sejak sapi terakhir melahirkan. Contoh: jika sapi melahirkan 6 bulan yang lalu, isi 6.',
              ),
              const SizedBox(height: 8),
              _buildNumberField(
                controller: _bulanLaktasiController,
                label: 'Bulan laktasi',
                suffix: 'bulan',
                isInteger: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<StatusKebuntingan>(
                initialValue: _statusKebuntingan,
                decoration: const InputDecoration(
                  labelText: 'Status kebuntingan',
                  border: OutlineInputBorder(),
                ),
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
                      if (_statusKebuntingan ==
                          StatusKebuntingan.tidakBunting) {
                        _bulanBuntingController.clear();
                      }
                    });
                  }
                },
              ),
              if (_statusKebuntingan == StatusKebuntingan.bunting) ...[
                const SizedBox(height: 12),
                _buildLabelWithInfo(
                  'Bulan bunting',
                  'Diisi umur kebuntingan dalam bulan. Contoh: jika kebuntingan sudah berjalan 7 bulan, isi 7.',
                ),
                const SizedBox(height: 8),
                _buildNumberField(
                  controller: _bulanBuntingController,
                  label: 'Bulan bunting',
                  suffix: 'bulan',
                  isInteger: true,
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Pemberian Pakan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (_pemberianPakan.isEmpty)
                _buildEmptyPakanState()
              else
                ...List.generate(
                  _pemberianPakan.length,
                  (index) => _buildKartuPakan(index, _pemberianPakan[index]),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _hitungEvaluasi,
                  child: const Text('Hitung Evaluasi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPakanState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        children: [
          Icon(Icons.restaurant_outlined, size: 40, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Belum ada bahan pakan yang ditambahkan',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            'Tekan tombol "Tambah Pakan" untuk mulai mengevaluasi pakan.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKartuPakan(int index, CampuranPakanItem item) {
    final totalBerat = PerhitunganNutrisi.hitungTotalBerat(_pemberianPakan);
    final persentase = PerhitunganNutrisi.hitungPersentaseBahan(
      item.jumlahKg,
      totalBerat,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.orange.shade50,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Bahan Pakan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => _hapusBahanPakan(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BahanPakan>(
              initialValue: item.bahan,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Pilih bahan pakan',
                border: OutlineInputBorder(),
              ),
              items: _semuaBahan.map((bahan) {
                return DropdownMenuItem<BahanPakan>(
                  value: bahan,
                  child: Text(bahan.nama, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _ubahBahanPakan(index, value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('jumlah_pakan_$index'),
              initialValue: item.jumlahKg == 0
                  ? ''
                  : item.jumlahKg.toStringAsFixed(2),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Jumlah diberikan',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _ubahJumlahPakan(index, value),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip(
                  'Komposisi',
                  '${persentase.toStringAsFixed(2)}%',
                ),
                _buildInfoChip('BK', '${item.bahan.bk.toStringAsFixed(2)}%'),
                _buildInfoChip(
                  'PK',
                  '${item.bahan.protein.toStringAsFixed(2)}%',
                ),
                _buildInfoChip('TDN', '${item.bahan.tdn.toStringAsFixed(2)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    bool isInteger = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Wajib diisi';
        }

        if (isInteger) {
          final parsed = int.tryParse(value);
          if (parsed == null) return 'Masukkan angka bulat yang valid';
          if (parsed < 0) return 'Tidak boleh negatif';
        } else {
          final parsed = double.tryParse(value.replaceAll(',', '.'));
          if (parsed == null) return 'Masukkan angka yang valid';
          if (parsed < 0) return 'Tidak boleh negatif';
        }

        return null;
      },
    );
  }

  Widget _buildTahapLaktasiInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.timeline, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          const Text('Tahap laktasi:'),
          const SizedBox(width: 6),
          Text(
            _labelTahapLaktasi(_tahapLaktasiTerdeteksi!),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildKartuHasilKebutuhan() {
    if (_hasilKebutuhan == null) return const SizedBox();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fact_check_outlined),
                SizedBox(width: 8),
                Text(
                  'Kebutuhan Nutrisi Sapi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildItemHasil('BK', _hasilKebutuhan!.kebutuhanBkKg, 'kg'),
            _buildItemHasil('Protein', _hasilKebutuhan!.kebutuhanProtein, 'kg'),
            _buildItemHasil('TDN', _hasilKebutuhan!.kebutuhanTdn, 'kg'),
            _buildItemHasil('ME', _hasilKebutuhan!.kebutuhanMe, ''),
          ],
        ),
      ),
    );
  }

  Widget _buildKartuHasilEvaluasi() {
    if (_hasilEvaluasi == null || _hasilCampuranPakan == null) {
      return const SizedBox();
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.summarize_outlined),
                SizedBox(width: 8),
                Text(
                  'Ringkasan Pemberian Pakan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildItemHasil(
              'Total Pakan',
              _hasilCampuranPakan!.totalBerat,
              'kg',
            ),
            _buildItemHasil('BK Campuran', _hasilCampuranPakan!.bk, '%'),
            _buildItemHasil(
              'Protein Campuran',
              _hasilCampuranPakan!.protein,
              '%',
            ),
            _buildItemHasil('TDN Campuran', _hasilCampuranPakan!.tdn, '%'),
            _buildItemHasil('ME Campuran', _hasilCampuranPakan!.me, ''),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Colors.grey.shade300),
            ),
            const Text(
              'Hasil Evaluasi Kecukupan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Text(
                _hasilEvaluasi!.kesimpulanUmum,
                style: const TextStyle(height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
            _buildKartuEvaluasiItem('BK', _hasilEvaluasi!.bk, 'kg'),
            _buildKartuEvaluasiItem('PK', _hasilEvaluasi!.protein, 'kg'),
            _buildKartuEvaluasiItem('TDN', _hasilEvaluasi!.tdn, 'kg'),
            _buildKartuEvaluasiItem('ME', _hasilEvaluasi!.me, ''),
            const SizedBox(height: 4),
            const Text(
              'Keterangan: hijau = berlebih, merah = kurang, hitam = pas.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKartuEvaluasiItem(
    String komponen,
    DetailEvaluasiNutrisi detail,
    String satuan,
  ) {
    final color = _warnaStatus(detail.status);

    String formatNilai(double nilai) {
      final angka = nilai.toStringAsFixed(2);
      return satuan.isEmpty ? angka : '$angka $satuan';
    }

    String formatSelisih(double nilai) {
      final prefix = nilai > 0 ? '+' : '';
      final angka = '$prefix${nilai.toStringAsFixed(2)}';
      return satuan.isEmpty ? angka : '$angka $satuan';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  komponen,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  detail.status,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBarisEvaluasi('Pemberian', formatNilai(detail.pemberian)),
          _buildBarisEvaluasi('Kebutuhan', formatNilai(detail.kebutuhan)),
          _buildBarisEvaluasi(
            'Selisih',
            formatSelisih(detail.selisih),
            valueColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildBarisEvaluasi(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildItemHasil(String label, double value, String suffix) {
    final text = suffix.isEmpty
        ? value.toStringAsFixed(2)
        : '${value.toStringAsFixed(2)} $suffix';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
