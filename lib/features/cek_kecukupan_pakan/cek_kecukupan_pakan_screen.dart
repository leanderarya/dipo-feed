import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_comparison_bar.dart';
import '../../core/widgets/app_sliver_header.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/bahan_pakan.dart';
import '../../data/models/campuran_pakan_item.dart';
import '../../data/models/fisiologi_sapi.dart';
import '../../data/models/kebutuhan_nutrien_sapi.dart';
import '../../data/sources/bahan_pakan_repository.dart';
import '../cek_kandungan_nutrisi/logic/perhitungan_nutrisi.dart';
import 'logic/perhitungan_kebutuhan_nutrien.dart';

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

  FisiologiSapi _fisiologi = FisiologiSapi.dara;

  List<BahanPakan> _semuaBahan = [];
  final List<CampuranPakanItem> _pemberianPakan = [];

  bool _isLoadingBahan = true;
  String? _errorBahan;
  KebutuhanNutrienSapi? _kebutuhanNutrien;
  _HasilEvaluasiRingkas? _hasilEvaluasi;

  @override
  void initState() {
    super.initState();
    _beratBadanController.addListener(_perbaruiKebutuhanOtomatis);
    _produksiSusuController.addListener(_perbaruiKebutuhanOtomatis);
    _lemakSusuController.addListener(_perbaruiKebutuhanOtomatis);
    _muatBahanPakan();
  }

  @override
  void dispose() {
    _beratBadanController.removeListener(_perbaruiKebutuhanOtomatis);
    _produksiSusuController.removeListener(_perbaruiKebutuhanOtomatis);
    _lemakSusuController.removeListener(_perbaruiKebutuhanOtomatis);
    _beratBadanController.dispose();
    _produksiSusuController.dispose();
    _lemakSusuController.dispose();
    super.dispose();
  }

  Future<void> _muatBahanPakan() async {
    try {
      await _repository.initialize();
      if (!mounted) return;
      setState(() {
        _semuaBahan = _repository.dataAktif;
        _isLoadingBahan = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorBahan = 'Gagal memuat bahan pakan: $e';
        _isLoadingBahan = false;
      });
    }
  }

  void _perbaruiKebutuhanOtomatis() {
    final beratBadan = _parseDouble(_beratBadanController.text);
    final produksiSusu = _parseDouble(_produksiSusuController.text);
    final lemakSusu = _parseDouble(_lemakSusuController.text);

    final bolehHitungDara = _fisiologi == FisiologiSapi.dara && beratBadan > 0;
    final bolehHitungKeringKandang =
        _fisiologi == FisiologiSapi.keringKandang && beratBadan > 0;
    final bolehHitungLaktasi =
        _fisiologi == FisiologiSapi.laktasi &&
        beratBadan > 0 &&
        produksiSusu > 0 &&
        lemakSusu > 0;

    if (bolehHitungDara || bolehHitungKeringKandang || bolehHitungLaktasi) {
      final kebutuhan = PerhitunganKebutuhanNutrien.hitungKebutuhan(
        fisiologi: _fisiologi,
        beratBadan: beratBadan,
        produksiSusuLiter: _fisiologi == FisiologiSapi.laktasi
            ? produksiSusu
            : null,
        lemakSusuPersen: _fisiologi == FisiologiSapi.laktasi ? lemakSusu : null,
      );

      if (!mounted) return;
      setState(() {
        _kebutuhanNutrien = kebutuhan;
        _hasilEvaluasi = null;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _kebutuhanNutrien = null;
      _hasilEvaluasi = null;
    });
  }

  void _ubahFisiologi(FisiologiSapi? value) {
    if (value == null) return;

    setState(() {
      _fisiologi = value;
      _hasilEvaluasi = null;

      if (_fisiologi != FisiologiSapi.laktasi) {
        _produksiSusuController.clear();
        _lemakSusuController.clear();
      }
    });

    _perbaruiKebutuhanOtomatis();
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
      _hasilEvaluasi = null;
    });
  }

  void _hapusBahanPakan(int index) {
    setState(() {
      _pemberianPakan.removeAt(index);
      _hasilEvaluasi = null;
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
      _hasilEvaluasi = null;
    });
  }

  void _ubahJumlahPakan(int index, String value) {
    final parsed = _parseDouble(value);
    setState(() {
      _pemberianPakan[index].jumlahKg = parsed < 0 ? 0 : parsed;
      _hasilEvaluasi = null;
    });
  }

  void _hitungEvaluasi() {
    if (!_formKey.currentState!.validate()) return;

    if (_kebutuhanNutrien == null) {
      final pesan = _fisiologi == FisiologiSapi.dara
          ? 'Isi BB sapi yang valid untuk menghitung kebutuhan nutrien Dara.'
          : _fisiologi == FisiologiSapi.laktasi
          ? 'Lengkapi BB, produksi susu, dan % lemak susu untuk menghitung kebutuhan nutrien Laktasi.'
          : 'Isi BB sapi yang valid untuk menghitung kebutuhan nutrien Kering Kandang.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pesan),
        ),
      );
      return;
    }

    if (_pemberianPakan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tambahkan minimal satu bahan pakan terlebih dahulu.'),
        ),
      );
      return;
    }

    final hasilPakan = PerhitunganNutrisi.hitungSemua(_pemberianPakan);
    final totalBerat = hasilPakan.totalBerat;
    if (totalBerat <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total pemberian pakan harus lebih dari 0 kg.'),
        ),
      );
      return;
    }

    final bkPemberianKg = totalBerat * (hasilPakan.bk / 100);
    final proteinPemberianKg = totalBerat * (hasilPakan.protein / 100);
    final tdnPemberianKg = totalBerat * (hasilPakan.tdn / 100);
    // Data Ca dan P per bahan pakan belum tersedia di master bahan pakan,
    // sehingga evaluasi sementara membaca pemberian Ca/P sebagai 0.
    const caPemberianGram = 0.0;
    const pPemberianGram = 0.0;

    final hasilEvaluasi = _HasilEvaluasiRingkas(
      bk: _DetailEvaluasi(
        kebutuhan: _kebutuhanNutrien!.kebutuhanBkKg,
        pemberian: bkPemberianKg,
      ),
      protein: _DetailEvaluasi(
        kebutuhan: _kebutuhanNutrien!.kebutuhanProteinKg,
        pemberian: proteinPemberianKg,
      ),
      tdn: _DetailEvaluasi(
        kebutuhan: _kebutuhanNutrien!.kebutuhanTdnKg,
        pemberian: tdnPemberianKg,
      ),
      ca: _DetailEvaluasi(
        kebutuhan: _kebutuhanNutrien!.kebutuhanCaGram,
        pemberian: caPemberianGram,
      ),
      p: _DetailEvaluasi(
        kebutuhan: _kebutuhanNutrien!.kebutuhanPGram,
        pemberian: pPemberianGram,
      ),
    );

    setState(() {
      _hasilEvaluasi = hasilEvaluasi;
    });
  }

  double _parseDouble(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  String _labelFisiologi(FisiologiSapi fisiologi) {
    switch (fisiologi) {
      case FisiologiSapi.dara:
        return 'Dara';
      case FisiologiSapi.laktasi:
        return 'Laktasi';
      case FisiologiSapi.keringKandang:
        return 'Kering Kandang';
    }
  }

  String? _validasiBeratBadan(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'BB wajib diisi';
    }

    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) {
      return 'Angka tidak valid';
    }
    if (parsed <= 0) {
      return 'BB harus lebih dari 0';
    }
    return null;
  }

  String? _validasiProduksiSusu(String? value) {
    if (_fisiologi != FisiologiSapi.laktasi) return null;
    if (value == null || value.trim().isEmpty) {
      return 'Wajib diisi';
    }

    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) {
      return 'Angka tidak valid';
    }
    if (parsed <= 0) {
      return 'Harus lebih dari 0';
    }
    return null;
  }

  String? _validasiLemakSusu(String? value) {
    if (_fisiologi != FisiologiSapi.laktasi) return null;
    if (value == null || value.trim().isEmpty) {
      return 'Wajib diisi';
    }

    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) {
      return 'Angka tidak valid';
    }
    if (parsed <= 0) {
      return 'Harus lebih dari 0';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: _isLoadingBahan
          ? const Center(child: CircularProgressIndicator())
          : _errorBahan != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_errorBahan!, textAlign: TextAlign.center),
              ),
            )
          : CustomScrollView(
              slivers: [
                const AppSliverHeader(
                  title: 'Cek Kecukupan Pakan',
                  subtitle:
                      'Evaluasi kecukupan nutrien pada pemberian pakan ternak.',
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    child: Column(
                      children: [
                        _buildFormInput(),
                        const SizedBox(height: 16),
                        _buildOutputSection(),
                        const SizedBox(height: 16),
                        _buildPemberianPakanSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFormInput() {
    return AppCard(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Sapi', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Text(
              'Fisiologi Sapi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<FisiologiSapi>(
              initialValue: _fisiologi,
              hint: const Text('-- Pilih Fisiologi --'),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
              ),
              items: FisiologiSapi.values.map((fisiologi) {
                return DropdownMenuItem<FisiologiSapi>(
                  value: fisiologi,
                  child: Text(_labelFisiologi(fisiologi)),
                );
              }).toList(),
              onChanged: _ubahFisiologi,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _beratBadanController,
              label: 'BB Sapi',
              suffix: 'kg',
              validator: _validasiBeratBadan,
            ),
            if (_fisiologi == FisiologiSapi.laktasi) ...[
              const SizedBox(height: 12),
              AppTextField(
                controller: _produksiSusuController,
                label: 'Produksi Susu',
                suffix: 'liter/ekor/hari',
                validator: _validasiProduksiSusu,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _lemakSusuController,
                label: '% Lemak Susu',
                suffix: '%',
                validator: _validasiLemakSusu,
              ),
              const SizedBox(height: 8),
              Text(
                _parseDouble(_lemakSusuController.text) > 0 &&
                        (_parseDouble(_lemakSusuController.text) < 2.5 ||
                            _parseDouble(_lemakSusuController.text) > 4.0)
                    ? 'Lemak susu di luar rentang normal (2.5%–4.0%). Perhitungan tetap dilakukan dengan ekstrapolasi.'
                    : 'Diisi sesuai dengan pengetahuan peternak, misalnya 3–3,5%.',
                style: TextStyle(
                  fontSize: 12,
                  color: _parseDouble(_lemakSusuController.text) > 0 &&
                          (_parseDouble(_lemakSusuController.text) < 2.5 ||
                              _parseDouble(_lemakSusuController.text) > 4.0)
                      ? AppColors.errorRed
                      : AppColors.textLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOutputSection() {
    if (_fisiologi == FisiologiSapi.dara) {
      if (_kebutuhanNutrien == null) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Kebutuhan Nutrien',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Isi BB sapi yang valid untuk menampilkan kebutuhan nutrien Dara berdasarkan NRC 1978.',
                style: TextStyle(height: 1.5),
              ),
            ],
          ),
        );
      }

      return _buildKartuKebutuhan();
    }

    if (_fisiologi == FisiologiSapi.laktasi && _kebutuhanNutrien == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Kebutuhan Nutrien',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Isi BB sapi, produksi susu, dan % lemak susu yang valid untuk menampilkan kebutuhan nutrien Laktasi berdasarkan NRC 1988.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      );
    }

    if (_fisiologi == FisiologiSapi.keringKandang && _kebutuhanNutrien == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Kebutuhan Nutrien',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Isi BB sapi yang valid untuk menampilkan kebutuhan nutrien Kering Kandang.',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
      );
    }

    return _buildKartuKebutuhan();
  }

  String _format(double value) => value.toStringAsFixed(2);

  Widget _buildKartuKebutuhan() {
    final kebutuhan = _kebutuhanNutrien!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kebutuhan Nutrien',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.3,
            children: [
              _buildNutrientMiniCard('BK (kg)', _format(kebutuhan.kebutuhanBkKg)),
              _buildNutrientMiniCard('PK (kg)', _format(kebutuhan.kebutuhanProteinKg)),
              _buildNutrientMiniCard('TDN (kg)', _format(kebutuhan.kebutuhanTdnKg)),
              _buildNutrientMiniCard('Ca (g)', _format(kebutuhan.kebutuhanCaGram)),
              _buildNutrientMiniCard('P (g)', _format(kebutuhan.kebutuhanPGram)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientMiniCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textGrey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPemberianPakanSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pemberian Pakan',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            _fisiologi == FisiologiSapi.dara
                ? 'Tambahkan bahan pakan untuk membandingkan BK, protein, dan TDN terhadap kebutuhan Dara.'
                : _fisiologi == FisiologiSapi.keringKandang
                ? 'Tambahkan bahan pakan untuk membandingkan BK, protein, dan TDN terhadap kebutuhan Kering Kandang.'
                : 'Tambahkan bahan pakan untuk membandingkan BK, protein, dan TDN terhadap kebutuhan Laktasi.',
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 16),
          if (_pemberianPakan.isEmpty)
            _buildEmptyPakanState()
          else
            ...List.generate(
              _pemberianPakan.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == _pemberianPakan.length - 1 ? 0 : 12,
                ),
                child: _buildKartuPakan(index, _pemberianPakan[index]),
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoadingBahan ? null : _tambahBahanPakan,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Tambah Bahan Pakan'),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _hitungEvaluasi,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Hitung Evaluasi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (_hasilEvaluasi != null) ...[
            const SizedBox(height: 20),
            _buildKartuHasilEvaluasi(),
          ],
        ],
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
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.eco_outlined,
            size: 48,
            color: AppColors.secondaryGreen.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pakan belum ditambahkan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Klik tombol tambah bahan pakan untuk mulai evaluasi.',
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _hapusBahanPakan(index),
                icon: const Icon(
                  Icons.close,
                  size: 20,
                  color: AppColors.errorRed,
                ),
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
                child: Text(
                  bahan.nama,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) _ubahBahanPakan(index, value);
            },
          ),
          const SizedBox(height: 12),
          AppTextField(
            initialValue: item.jumlahKg == 0
                ? ''
                : item.jumlahKg.toStringAsFixed(2),
            label: 'Jumlah',
            suffix: 'kg',
            onChanged: (value) => _ubahJumlahPakan(index, value),
          ),
        ],
      ),
    );
  }

  Widget _buildKartuHasilEvaluasi() {
    final hasil = _hasilEvaluasi!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.expertPurple.withValues(alpha: 0.08), // Soft brand purple background
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.expertPurple.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: AppColors.expertPurple,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Hasil Evaluasi Nutrisi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.expertPurple,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Comparison Panel inside a high-contrast white card that adapts beautifully!
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppComparisonBar(
                  label: 'Bahan Kering (BK)',
                  current: hasil.bk.pemberian,
                  limit: hasil.bk.kebutuhan,
                  unit: 'kg',
                ),
                const SizedBox(height: 20),
                AppComparisonBar(
                  label: 'Protein',
                  current: hasil.protein.pemberian,
                  limit: hasil.protein.kebutuhan,
                  unit: 'kg',
                ),
                const SizedBox(height: 20),
                AppComparisonBar(
                  label: 'TDN',
                  current: hasil.tdn.pemberian,
                  limit: hasil.tdn.kebutuhan,
                  unit: 'kg',
                ),
                const SizedBox(height: 20),
                AppComparisonBar(
                  label: 'Ca',
                  current: hasil.ca.pemberian,
                  limit: hasil.ca.kebutuhan,
                  unit: 'gram',
                ),
                const SizedBox(height: 20),
                AppComparisonBar(
                  label: 'P',
                  current: hasil.p.pemberian,
                  limit: hasil.p.kebutuhan,
                  unit: 'gram',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Catatan: nilai pemberian Ca dan P saat ini masih 0 karena data kandungan Ca/P pada bahan pakan belum tersedia.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.expertPurple,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // KESIMPULAN UMUM with high-intensity solid purple background!
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.expertPurple, // High-intensity brand purple
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
          ),
        ],
      ),
    );
  }
}

class _DetailEvaluasi {
  final double kebutuhan;
  final double pemberian;

  const _DetailEvaluasi({
    required this.kebutuhan,
    required this.pemberian,
  });

  double get selisih => pemberian - kebutuhan;

  String get status {
    if (selisih > 0.0001) return 'Berlebih';
    if (selisih < -0.0001) return 'Kurang';
    return 'Cukup';
  }
}

class _HasilEvaluasiRingkas {
  final _DetailEvaluasi bk;
  final _DetailEvaluasi protein;
  final _DetailEvaluasi tdn;
  final _DetailEvaluasi ca;
  final _DetailEvaluasi p;

  const _HasilEvaluasiRingkas({
    required this.bk,
    required this.protein,
    required this.tdn,
    required this.ca,
    required this.p,
  });

  String get kesimpulanUmum {
    final semuaStatus = [
      bk.status,
      protein.status,
      tdn.status,
      ca.status,
      p.status,
    ];

    if (semuaStatus.every((status) => status == 'Cukup')) {
      return 'Pakan yang diberikan sudah sesuai dengan kebutuhan nutrien sapi.';
    }

    if (semuaStatus.any((status) => status == 'Kurang')) {
      return 'Pakan yang diberikan belum mencukupi seluruh kebutuhan nutrien sapi.';
    }

    return 'Pakan yang diberikan cenderung berlebih pada beberapa komponen nutrien.';
  }
}
