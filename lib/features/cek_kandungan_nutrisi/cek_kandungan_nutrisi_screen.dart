import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/status_perhitungan.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/indonesian_number_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_sliver_header.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/bahan_pakan.dart';
import '../../data/models/campuran_pakan_item.dart';
import '../../data/models/fisiologi_sapi.dart';
import '../../data/models/hasil_pakan_terpilih.dart';
import '../../data/sources/bahan_pakan_repository.dart';
import '../master_pakan/master_pakan_screen.dart';
import 'logic/evaluasi_standar_nutrien.dart';
import 'logic/perhitungan_nutrisi.dart';
import 'widgets/evaluasi_standar_card.dart';
import 'widgets/searchable_bahan_pakan_dialog.dart';

class CekKandunganNutrisiScreen extends StatefulWidget {
  final bool modePilihUntukEvaluasi;
  final BahanPakanRepository? repository;

  const CekKandunganNutrisiScreen({
    super.key,
    this.modePilihUntukEvaluasi = false,
    this.repository,
  });

  @override
  State<CekKandunganNutrisiScreen> createState() =>
      _CekKandunganNutrisiScreenState();
}

class _CekKandunganNutrisiScreenState extends State<CekKandunganNutrisiScreen> {
  late final BahanPakanRepository _repository;

  List<BahanPakan> _semuaBahan = [];
  final List<CampuranPakanItem> _campuran = [];
  FisiologiSapi _fisiologi = FisiologiSapi.laktasi;
  HasilPerhitunganNutrisi? _hasilTerhitung;
  StatusPerhitungan _statusPerhitungan = StatusPerhitungan.belumDihitung;
  String? _pesanPerhitungan;
  int _tahapAktif = 0;
  final Set<CampuranPakanItem> _inputJumlahTidakValid = {};
  final Set<CampuranPakanItem> _inputHargaTidakValid = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BahanPakanRepository();
    _muatBahanPakan();
  }

  Future<void> _muatBahanPakan() async {
    try {
      await _repository.initialize();
      if (!mounted) return;
      setState(() {
        _semuaBahan = _repository.dataAktif;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final errorMsg = 'Gagal memuat bahan pakan: $e';
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
      AppToast.showError(context, errorMsg);
    }
  }

  Future<void> _bukaManajemenMaster() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MasterPakanScreen(repository: _repository),
      ),
    );
    if (!mounted) return;
    await _repository.refresh();
    if (!mounted) return;
    setState(() {
      _semuaBahan = _repository.dataAktif;
      _reconcileCampuran();
      _invalidasiPerhitungan();
    });
  }

  void _reconcileCampuran() {
    final bahanById = <int, BahanPakan>{
      for (final bahan in _semuaBahan) bahan.id: bahan,
    };
    final campuranTersinkron = <CampuranPakanItem>[];
    for (final item in _campuran) {
      final bahanTerbaru = bahanById[item.bahan.id];
      if (bahanTerbaru != null) {
        campuranTersinkron.add(item.copyWith(bahan: bahanTerbaru));
      }
    }
    _campuran
      ..clear()
      ..addAll(campuranTersinkron);
    _inputJumlahTidakValid.clear();
    _inputHargaTidakValid.clear();
  }

  Future<void> _tambahBahan() async {
    if (_semuaBahan.isEmpty) return;

    final bahanTerpilihIds = _campuran.map((item) => item.bahan.id).toSet();
    final bahanBaru = await SearchableBahanPakanDialog.show(
      context: context,
      semuaBahan: _semuaBahan,
      bahanTerpilihIds: bahanTerpilihIds,
    );

    if (bahanBaru == null) return;

    if (!mounted) return;
    if (bahanTerpilihIds.contains(bahanBaru.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bahan "${bahanBaru.nama}" sudah ada dalam campuran.'),
        ),
      );
      return;
    }

    setState(() {
      _campuran.add(
        CampuranPakanItem(
          bahan: bahanBaru,
          jumlahKg: 0,
          hargaPerKg: bahanBaru.hargaDefault,
        ),
      );
      _invalidasiPerhitungan();
    });
  }

  void _hapusBahan(int index) {
    setState(() {
      final item = _campuran.removeAt(index);
      _inputJumlahTidakValid.remove(item);
      _inputHargaTidakValid.remove(item);
      _invalidasiPerhitungan();
    });
  }

  Future<void> _pilihAtauUbahBahan(int index) async {
    final bahanTerpilihIds = _campuran.map((item) => item.bahan.id).toSet();
    final itemLama = _campuran[index];

    final bahanBaru = await SearchableBahanPakanDialog.show(
      context: context,
      semuaBahan: _semuaBahan,
      bahanTerpilihIds: bahanTerpilihIds,
      bahanSaatIni: itemLama.bahan,
    );

    if (bahanBaru == null || bahanBaru.id == itemLama.bahan.id) return;

    if (!mounted) return;
    final sudahDipakaiOlehItemLain = _campuran.asMap().entries.any((entry) {
      return entry.key != index && entry.value.bahan.id == bahanBaru.id;
    });

    if (sudahDipakaiOlehItemLain) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bahan "${bahanBaru.nama}" sudah dipilih pada item lain.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _inputJumlahTidakValid.remove(itemLama);
      _inputHargaTidakValid.remove(itemLama);
      _campuran[index] = itemLama.copyWith(
        bahan: bahanBaru,
        hargaPerKg: bahanBaru.hargaDefault,
      );
      _invalidasiPerhitungan();
    });
  }

  void _ubahJumlahKg(int index, String value) {
    final input = value.trim();
    final jumlah = input.isEmpty
        ? 0.0
        : IndonesianNumberFormatter.tryParse(input)?.toDouble();
    final item = _campuran[index];
    setState(() {
      item.jumlahKg = jumlah ?? double.nan;
      if (input.isNotEmpty &&
          (jumlah == null ||
              jumlah.isNegative ||
              !IndonesianNumberFormatter.isSupportedMagnitude(jumlah))) {
        _inputJumlahTidakValid.add(item);
      } else {
        _inputJumlahTidakValid.remove(item);
      }
      _invalidasiPerhitungan();
    });
  }

  void _ubahHargaPerKg(int index, String value) {
    final input = value.trim();
    final parsed = input.isEmpty
        ? 0.0
        : IndonesianNumberFormatter.tryParse(value);
    final item = _campuran[index];
    setState(() {
      item.hargaPerKg = parsed?.toDouble() ?? double.nan;
      if (input.isNotEmpty &&
          (parsed == null ||
              parsed.isNegative ||
              !IndonesianNumberFormatter.isSupportedMagnitude(parsed))) {
        _inputHargaTidakValid.add(item);
      } else {
        _inputHargaTidakValid.remove(item);
      }
      _invalidasiPerhitungan();
    });
  }

  void _invalidasiPerhitungan() {
    _hasilTerhitung = null;
    _statusPerhitungan = StatusPerhitungan.belumDihitung;
    _pesanPerhitungan = null;
    if (_tahapAktif > 0) {
      _tahapAktif = 0;
    }
  }

  void _hitungManual() {
    try {
      if (_campuran.isEmpty) {
        throw const FormatException('Tambahkan minimal satu bahan pakan.');
      }
      if (_campuran.any(
        (item) => !item.bahan.isValidForCalculation(requirePositiveBk: true),
      )) {
        throw const FormatException('Data bahan pakan yang dipilih tidak valid.');
      }
      if (_inputJumlahTidakValid.isNotEmpty ||
          _inputHargaTidakValid.isNotEmpty ||
          _campuran.any(
            (item) =>
                item.jumlahKg < 0 ||
                !IndonesianNumberFormatter.isSupportedMagnitude(item.jumlahKg) ||
                item.hargaPerKg < 0 ||
                !IndonesianNumberFormatter.isSupportedMagnitude(item.hargaPerKg),
          )) {
        throw const FormatException('Jumlah atau harga pakan tidak valid.');
      }

      final hasil = PerhitunganNutrisi.hitungSemua(_campuran);
      if (!_hasilPerhitunganValid(hasil)) {
        throw const FormatException('Hasil perhitungan nutrisi tidak valid.');
      }
      if (hasil.totalBerat <= 0) {
        throw const FormatException(
          'Total campuran pakan harus lebih dari 0 kg.',
        );
      }

      setState(() {
        _hasilTerhitung = hasil;
        _statusPerhitungan = StatusPerhitungan.berhasil;
        _pesanPerhitungan = null;
        _tahapAktif = 1;
      });
      if (mounted) {
        AppToast.showSuccess(
          context,
          'Kandungan nutrisi pakan berhasil dihitung.',
          title: 'Perhitungan Berhasil',
        );
      }
    } catch (error) {
      final pesan = error is FormatException
          ? error.message
          : 'Perhitungan nutrisi gagal dilakukan.';
      setState(() {
        _hasilTerhitung = null;
        _statusPerhitungan = StatusPerhitungan.gagal;
        _pesanPerhitungan = pesan;
      });
      if (mounted) {
        AppToast.showError(context, pesan, title: 'Perhitungan Gagal');
      }
    }
  }

  bool _hasilPerhitunganValid(HasilPerhitunganNutrisi hasil) {
    final values = [
      hasil.totalBerat,
      hasil.totalBiaya,
      hasil.hargaRataRata,
      hasil.bk,
      hasil.abu,
      hasil.lemak,
      hasil.serat,
      hasil.protein,
      hasil.tdn,
      hasil.ca,
      hasil.p,
      hasil.me,
    ];
    return values.every(
      (value) =>
          IndonesianNumberFormatter.isSupportedMagnitude(value) && value >= 0,
    );
  }

  void _kembaliTahap() {
    if (_tahapAktif == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _tahapAktif--);
  }

  bool get _hasEnteredData => _campuran.isNotEmpty;

  Future<void> _handleSystemBack() async {
    if (_tahapAktif > 0) {
      _kembaliTahap();
      return;
    }
    if (!_hasEnteredData) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari fitur?'),
        content: const Text('Data yang sudah diisi akan hilang.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (shouldExit == true && mounted) Navigator.of(context).pop();
  }

  void _gunakanUntukEvaluasi() {
    final hasil = _hasilTerhitung;
    if (_statusPerhitungan != StatusPerhitungan.berhasil || hasil == null) {
      AppToast.showWarning(
        context,
        'Hitung campuran pakan sebelum digunakan untuk evaluasi.',
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
    final hasil = _statusPerhitungan == StatusPerhitungan.berhasil
        ? _hasilTerhitung
        : null;
    final evaluasiStandar = hasil == null
        ? null
        : EvaluasiStandarNutrienHelper.evaluasi(
            hasil: hasil,
            fisiologi: _fisiologi,
          );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundKrem,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_errorMessage!, textAlign: TextAlign.center),
                    ),
                  )
                : _buildStepperBody(hasil, evaluasiStandar),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _buildNavigationControls(),
          ),
        ),
      ),
    );
  }

  Widget _buildStepperBody(
    HasilPerhitunganNutrisi? hasil,
    HasilEvaluasiStandarNutrien? evaluasiStandar,
  ) {
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 275),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _tahapAktif == 0
              ? SizedBox(
                  height: 210,
                  child: CustomScrollView(
                    slivers: [
                      AppSliverHeader(
                        title: 'Cek Kandungan Pakan',
                        subtitle: 'Cek kandungan nutrisi pada pakan.',
                        onBackTap: _handleSystemBack,
                        actions: [
                          IconButton(
                            tooltip: 'Database Pakan',
                            onPressed: _isLoading ? null : _bukaManajemenMaster,
                            icon: const Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : _buildCompactHeader(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressIndicator(),
                const SizedBox(height: 16),
                _buildTahapAktif(hasil, evaluasiStandar),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top,
        left: 8,
        right: 16,
      ),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: _kembaliTahap,
            ),
            const Expanded(
              child: Text(
                'Cek Kandungan Pakan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Database Pakan',
              onPressed: _isLoading ? null : _bukaManajemenMaster,
              icon: const Icon(
                Icons.inventory_2_outlined,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final stepTitles = ['Komposisi Pakan', 'Hasil Evaluasi'];
    final labels = [
      'Komposisi Campuran Pakan',
      'Hasil Analisis & Evaluasi Nutrien',
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(2, (index) {
              final isCurrent = index == _tahapAktif;
              final isCompleted = index < _tahapAktif;
              final canTap = index < _tahapAktif;

              return Expanded(
                child: InkWell(
                  onTap: canTap
                      ? () {
                          setState(() => _tahapAktif = index);
                        }
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (index > 0)
                              Expanded(
                                child: Container(
                                  height: 2.5,
                                  color: index <= _tahapAktif
                                      ? AppColors.secondaryGreen
                                      : Colors.grey.shade300,
                                ),
                              ),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppColors.primaryBlue
                                    : isCompleted
                                        ? AppColors.secondaryGreen
                                        : Colors.grey.shade200,
                                shape: BoxShape.circle,
                                boxShadow: isCurrent
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryBlue
                                              .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isCurrent
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                              ),
                            ),
                            if (index < 1)
                              Expanded(
                                child: Container(
                                  height: 2.5,
                                  color: index < _tahapAktif
                                      ? AppColors.secondaryGreen
                                      : Colors.grey.shade300,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stepTitles[index],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isCurrent
                                ? FontWeight.w800
                                : isCompleted
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                            color: isCurrent
                                ? AppColors.primaryBlue
                                : isCompleted
                                    ? AppColors.textDark
                                    : AppColors.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.backgroundCream,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _tahapAktif == 0
                      ? Icons.science_outlined
                      : Icons.auto_awesome_rounded,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tahap ${_tahapAktif + 1} dari 2: ${labels[_tahapAktif]}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTahapAktif(
    HasilPerhitunganNutrisi? hasil,
    HasilEvaluasiStandarNutrien? evaluasiStandar,
  ) {
    if (_tahapAktif == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKartuStandarFisiologi(),
          const SizedBox(height: 16),
          if (_campuran.isEmpty)
            _buildEmptyState()
          else ...[
            const Text(
              'Bahan Campuran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._campuran.asMap().entries.map(
              (entry) => _buildKartuBahan(entry.key, entry.value),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _tambahBahan,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Tambah Bahan Pakan'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildPerhitunganStatus(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (evaluasiStandar != null && hasil != null) ...[
          EvaluasiStandarCard(
            evaluasi: evaluasiStandar,
            totalBeratKg: hasil.totalBerat,
            totalBiaya: hasil.totalBiaya,
          ),
          const SizedBox(height: 16),
          _buildPerhitunganStatus(),
        ] else
          const AppCard(
            child: Text(
              'Lengkapi komposisi campuran pakan terlebih dahulu untuk melihat hasil.',
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationControls() {
    if (_tahapAktif == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _hitungManual,
              child: const Text('Hitung Kandungan Nutrisi'),
            ),
          ),
          if (widget.modePilihUntukEvaluasi && _campuran.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _gunakanUntukEvaluasi,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentOrange,
                ),
                child: const Text('Gunakan untuk Evaluasi'),
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _kembaliTahap,
            child: const Text('Kembali'),
          ),
        ),
        if (widget.modePilihUntukEvaluasi) ...[
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _gunakanUntukEvaluasi,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
              ),
              child: const Text('Gunakan untuk Evaluasi'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPerhitunganStatus() {
    final statusText = switch (_statusPerhitungan) {
      StatusPerhitungan.belumDihitung => 'Belum dihitung',
      StatusPerhitungan.berhasil => 'Perhitungan berhasil',
      StatusPerhitungan.gagal => 'Gagal menghitung',
    };
    final statusMessage = switch (_statusPerhitungan) {
      StatusPerhitungan.belumDihitung =>
        'Tekan Hitung untuk menghitung kandungan campuran.',
      StatusPerhitungan.berhasil =>
        'Hasil merupakan snapshot dari input terakhir.',
      StatusPerhitungan.gagal =>
        _pesanPerhitungan ?? 'Perhitungan nutrisi gagal dilakukan.',
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(statusText, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(statusMessage),
          const SizedBox(height: 12),
          FilledButton(onPressed: _hitungManual, child: const Text('Hitung')),
        ],
      ),
    );
  }

  Widget _buildKartuStandarFisiologi() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.category_outlined, color: AppColors.primaryBlue),
              SizedBox(width: 8),
              Text(
                'Standar Evaluasi Nutrien',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Pilih fisiologi sapi untuk membandingkan kualitas campuran dengan standar nutrien umum.',
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<FisiologiSapi>(
            initialValue: _fisiologi,
            items: FisiologiSapi.values.map((item) {
              return DropdownMenuItem<FisiologiSapi>(
                value: item,
                child: Text(_labelFisiologi(item)),
              );
            }).toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _fisiologi = value;
                _invalidasiPerhitungan();
              });
            },
            decoration: InputDecoration(
              labelText: 'Fisiologi Sapi',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppCard(
      width: double.infinity,
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
      key: ValueKey('kartu_bahan_${item.bahan.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pilihAtauUbahBahan(index),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundKrem,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.textLight.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.bahan.nama,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${item.bahan.kategori} • BK: ${IndonesianNumberFormatter.isSupportedMagnitude(item.bahan.bk) ? '${IndonesianNumberFormatter.format(item.bahan.bk, decimals: 1)}%' : '-'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () => _hapusBahan(index),
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.close,
                  color: AppColors.errorRed,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  key: ValueKey('jumlah_${item.bahan.id}'),
                  initialValue:
                      item.jumlahKg == 0 ||
                          !IndonesianNumberFormatter.isSupportedMagnitude(
                            item.jumlahKg,
                          )
                      ? ''
                      : IndonesianNumberFormatter.format(
                          item.jumlahKg,
                          decimals: 2,
                        ),
                  label: 'Jumlah (kg)',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => _ubahJumlahKg(index, v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppTextField(
                  key: ValueKey('harga_${item.bahan.id}'),
                  initialValue:
                      item.hargaPerKg == 0 ||
                          !IndonesianNumberFormatter.isSupportedMagnitude(
                            item.hargaPerKg,
                          )
                      ? ''
                      : CurrencyFormatter.formatRupiah(
                          item.hargaPerKg,
                          withSymbol: false,
                          withDecimals: false,
                        ),
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
}
