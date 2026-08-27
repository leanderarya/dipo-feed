import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/status_perhitungan.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/indonesian_number_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_sliver_header.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/bahan_pakan.dart';
import '../../data/models/campuran_pakan_item.dart';
import '../../data/models/fisiologi_sapi.dart';
import '../../data/models/kebutuhan_nutrien_sapi.dart';
import '../../data/sources/bahan_pakan_repository.dart';
import '../cek_kandungan_nutrisi/logic/perhitungan_nutrisi.dart';
import 'logic/evaluasi_kecukupan_nutrien.dart';
import 'logic/perhitungan_kebutuhan_nutrien.dart';
import 'widgets/evaluasi_kecukupan_card.dart';

class CekKecukupanPakanScreen extends StatefulWidget {
  const CekKecukupanPakanScreen({super.key, this.repository});

  final BahanPakanRepository? repository;

  @override
  State<CekKecukupanPakanScreen> createState() =>
      _CekKecukupanPakanScreenState();
}

class _CekKecukupanPakanScreenState extends State<CekKecukupanPakanScreen> {
  final _formKey = GlobalKey<FormState>();
  late final BahanPakanRepository _repository;

  final TextEditingController _beratBadanController = TextEditingController();
  final TextEditingController _produksiSusuController = TextEditingController();
  final TextEditingController _lemakSusuController = TextEditingController();

  FisiologiSapi _fisiologi = FisiologiSapi.dara;

  List<BahanPakan> _semuaBahan = [];
  final List<CampuranPakanItem> _pemberianPakan = [];
  final List<ValueKey<int>> _pakanRowKeys = [];
  final Set<int> _jumlahPakanTidakValid = {};
  int _nextPakanRowKey = 0;

  bool _isLoadingBahan = true;
  String? _errorBahan;
  KebutuhanNutrienSapi? _kebutuhanNutrien;
  HasilEvaluasiKecukupanNutrien? _hasilEvaluasi;
  StatusPerhitungan _statusPerhitungan = StatusPerhitungan.belumDihitung;
  int _tahapAktif = 0;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BahanPakanRepository();
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
      final kebutuhan = _validasiKebutuhan(
        PerhitunganKebutuhanNutrien.hitungKebutuhan(
          fisiologi: _fisiologi,
          beratBadan: beratBadan,
          produksiSusuLiter: _fisiologi == FisiologiSapi.laktasi
              ? produksiSusu
              : null,
          lemakSusuPersen: _fisiologi == FisiologiSapi.laktasi
              ? lemakSusu
              : null,
        ),
      );

      if (!mounted) return;
      setState(() {
        _kebutuhanNutrien = kebutuhan;
      });
      _perbaruiEvaluasiRealtime();
      return;
    }

    if (!mounted) return;
    setState(() {
      _kebutuhanNutrien = null;
      _hasilEvaluasi = null;
      _statusPerhitungan = StatusPerhitungan.belumDihitung;
    });
  }

  void _ubahFisiologi(FisiologiSapi? value) {
    if (value == null) return;

    setState(() {
      _fisiologi = value;
      _hasilEvaluasi = null;
      _statusPerhitungan = StatusPerhitungan.belumDihitung;

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
      AppToast.showWarning(
        context,
        'Semua bahan pakan aktif sudah ditambahkan.',
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
      _pakanRowKeys.add(ValueKey(_nextPakanRowKey++));
    });
    _perbaruiEvaluasiRealtime();
  }

  void _hapusBahanPakan(int index) {
    final invalidAfterRemove = _jumlahPakanTidakValid
        .where((invalidIndex) => invalidIndex != index)
        .map(
          (invalidIndex) =>
              invalidIndex > index ? invalidIndex - 1 : invalidIndex,
        )
        .toSet();
    setState(() {
      _pemberianPakan.removeAt(index);
      _pakanRowKeys.removeAt(index);
      _jumlahPakanTidakValid
        ..clear()
        ..addAll(invalidAfterRemove);
    });
    _perbaruiEvaluasiRealtime();
  }

  void _ubahBahanPakan(int index, BahanPakan bahanBaru) {
    final sudahDipakai = _pemberianPakan.asMap().entries.any((entry) {
      return entry.key != index && entry.value.bahan.id == bahanBaru.id;
    });

    if (sudahDipakai) {
      AppToast.showWarning(
        context,
        'Bahan tersebut sudah dipilih pada item lain.',
      );
      return;
    }

    setState(() {
      _pemberianPakan[index] = _pemberianPakan[index].copyWith(
        bahan: bahanBaru,
        hargaPerKg: bahanBaru.hargaDefault,
      );
    });
    _perbaruiEvaluasiRealtime();
  }

  void _ubahJumlahPakan(int index, String value) {
    final input = value.trim();
    final parsed = IndonesianNumberFormatter.tryParse(input)?.toDouble();
    final valid =
        input.isEmpty ||
        (parsed != null &&
            IndonesianNumberFormatter.isSupportedMagnitude(parsed) &&
            parsed >= 0);
    setState(() {
      if (input.isEmpty) {
        _pemberianPakan[index].jumlahKg = 0;
        _jumlahPakanTidakValid.remove(index);
      } else if (valid) {
        _pemberianPakan[index].jumlahKg = parsed!;
        _jumlahPakanTidakValid.remove(index);
      } else {
        _jumlahPakanTidakValid.add(index);
      }
    });
    _perbaruiEvaluasiRealtime();
  }

  void _perbaruiEvaluasiRealtime() {
    if (_kebutuhanNutrien == null) {
      if (_hasilEvaluasi != null || _statusPerhitungan != StatusPerhitungan.belumDihitung) {
        setState(() {
          _hasilEvaluasi = null;
          _statusPerhitungan = StatusPerhitungan.belumDihitung;
        });
      }
      return;
    }

    if (_pemberianPakan.isEmpty ||
        _jumlahPakanTidakValid.isNotEmpty ||
        _pemberianPakan.every((item) => item.jumlahKg <= 0)) {
      if (_hasilEvaluasi != null || _statusPerhitungan != StatusPerhitungan.belumDihitung) {
        setState(() {
          _hasilEvaluasi = null;
          _statusPerhitungan = StatusPerhitungan.belumDihitung;
        });
      }
      return;
    }

    if (_repository.semuaData.any((bahan) => !bahan.isValidForCalculation()) ||
        _pemberianPakan.any(
          (item) => !item.bahan.isValidForCalculation(requirePositiveBk: true),
        )) {
      if (_statusPerhitungan != StatusPerhitungan.gagal) {
        setState(() {
          _hasilEvaluasi = null;
          _statusPerhitungan = StatusPerhitungan.gagal;
        });
      }
      return;
    }

    final hasilPakan = PerhitunganNutrisi.hitungSemua(_pemberianPakan);
    if (!_hasilNutrisiValid(hasilPakan) || hasilPakan.totalBerat <= 0) {
      if (_statusPerhitungan != StatusPerhitungan.gagal) {
        setState(() {
          _hasilEvaluasi = null;
          _statusPerhitungan = StatusPerhitungan.gagal;
        });
      }
      return;
    }

    final hasilEvaluasi = HasilEvaluasiKecukupanNutrien.hitung(
      fisiologi: _fisiologi,
      kebutuhan: _kebutuhanNutrien!,
      nutrisiPemberian: hasilPakan,
      daftarPemberian: _pemberianPakan,
    );

    final nilaiEvaluasi = [
      hasilEvaluasi.bk.kebutuhan,
      hasilEvaluasi.bk.pemberian,
      hasilEvaluasi.protein.kebutuhan,
      hasilEvaluasi.protein.pemberian,
      hasilEvaluasi.tdn.kebutuhan,
      hasilEvaluasi.tdn.pemberian,
      hasilEvaluasi.ca.kebutuhan,
      hasilEvaluasi.ca.pemberian,
      hasilEvaluasi.p.kebutuhan,
      hasilEvaluasi.p.pemberian,
    ];
    if (!_nilaiValid(nilaiEvaluasi)) {
      if (_statusPerhitungan != StatusPerhitungan.gagal) {
        setState(() {
          _hasilEvaluasi = null;
          _statusPerhitungan = StatusPerhitungan.gagal;
        });
      }
      return;
    }

    setState(() {
      _hasilEvaluasi = hasilEvaluasi;
      _statusPerhitungan = StatusPerhitungan.berhasil;
    });
  }

  bool _validasiTahapSatu() {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      AppToast.showWarning(context, 'Lengkapi data sapi terlebih dahulu.');
      return false;
    }

    _perbaruiKebutuhanOtomatis();
    if (_kebutuhanNutrien == null) {
      AppToast.showWarning(
        context,
        'Data sapi belum valid untuk menghitung kebutuhan.',
      );
      return false;
    }
    return true;
  }

  bool _validasiTahapDua() {
    if (_pemberianPakan.isEmpty) {
      AppToast.showWarning(context, 'Tambahkan minimal 1 bahan pakan.');
      return false;
    }
    if (_jumlahPakanTidakValid.isNotEmpty) {
      AppToast.showError(context, 'Format jumlah pakan ada yang tidak valid.');
      return false;
    }
    final totalJumlah = _pemberianPakan.fold<double>(
      0,
      (sum, item) => sum + item.jumlahKg,
    );
    if (totalJumlah <= 0) {
      AppToast.showWarning(context, 'Masukkan jumlah pemberian pakan (kg).');
      return false;
    }
    if (_pemberianPakan.any((item) => item.jumlahKg <= 0)) {
      AppToast.showWarning(
        context,
        'Pastikan semua bahan pakan memiliki jumlah lebih dari 0 kg.',
      );
      return false;
    }
    return true;
  }

  void _lanjutTahap() {
    if (_tahapAktif == 0) {
      if (_validasiTahapSatu()) {
        setState(() => _tahapAktif = 1);
      }
    } else if (_tahapAktif == 1) {
      if (_validasiTahapDua()) {
        _perbaruiEvaluasiRealtime();
        if (_statusPerhitungan == StatusPerhitungan.berhasil &&
            _hasilEvaluasi != null) {
          setState(() => _tahapAktif = 2);
          AppToast.showSuccess(
            context,
            'Kecukupan pakan berhasil dihitung!',
          );
        } else {
          AppToast.showError(
            context,
            'Perhitungan nutrisi gagal. Periksa data pakan.',
          );
        }
      }
    }
  }

  void _kembaliTahap() {
    if (_tahapAktif == 0) {
      _handleSystemBack();
      return;
    }
    setState(() => _tahapAktif--);
  }

  bool get _hasEnteredData =>
      _beratBadanController.text.trim().isNotEmpty ||
      _produksiSusuController.text.trim().isNotEmpty ||
      _lemakSusuController.text.trim().isNotEmpty ||
      _pemberianPakan.isNotEmpty;

  Future<void> _handleSystemBack() async {
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

  double _parseDouble(String value) {
    final parsed = IndonesianNumberFormatter.tryParse(value)?.toDouble();
    return parsed != null &&
            IndonesianNumberFormatter.isSupportedMagnitude(parsed)
        ? parsed
        : 0;
  }

  KebutuhanNutrienSapi? _validasiKebutuhan(KebutuhanNutrienSapi? kebutuhan) {
    if (kebutuhan == null) return null;
    final values = [
      kebutuhan.kebutuhanBkKg,
      kebutuhan.kebutuhanProteinKg,
      kebutuhan.kebutuhanTdnKg,
      kebutuhan.kebutuhanCaGram,
      kebutuhan.kebutuhanPGram,
    ];
    return values.every(
          (value) =>
              IndonesianNumberFormatter.isSupportedMagnitude(value) &&
              value >= 0,
        )
        ? kebutuhan
        : null;
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

    final parsed = IndonesianNumberFormatter.tryParse(value)?.toDouble();
    if (parsed == null || !parsed.isFinite) {
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

    final parsed = IndonesianNumberFormatter.tryParse(value)?.toDouble();
    if (parsed == null || !parsed.isFinite) {
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

    final parsed = IndonesianNumberFormatter.tryParse(value)?.toDouble();
    if (parsed == null || !parsed.isFinite) {
      return 'Angka tidak valid';
    }
    if (parsed <= 0) {
      return 'Harus lebih dari 0';
    }
    return null;
  }

  String? get _warningLemakSusu {
    if (_fisiologi != FisiologiSapi.laktasi) return null;
    final val = _parseDouble(_lemakSusuController.text);
    if (val <= 0) return null;
    if (val < 2.5) return 'Kadar lemak susu terlalu rendah (< 2,5%)';
    if (val > 4.0) return 'Kadar lemak susu melebihi standar (> 4,0%)';
    return null;
  }

  Widget _buildRangeWarning(String message) {
    return Row(
      children: [
        const Icon(
          Icons.info_outline,
          size: 13,
          color: AppColors.accentOrange,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.accentOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleSystemBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundCream,
        bottomNavigationBar: !_isLoadingBahan && _errorBahan == null
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _buildNavigationControls(),
                ),
              )
            : null,
        body: _isLoadingBahan
            ? const Center(child: CircularProgressIndicator())
            : _errorBahan != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_errorBahan!, textAlign: TextAlign.center),
                ),
              )
            : _buildStepperBody(),
      ),
    );
  }

  Widget _buildStepperBody() {
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
                        title: 'Cek Kecukupan Pakan',
                        subtitle: 'Cek kecukupan nutrien dan pemberian pakan.',
                        onBackTap: _handleSystemBack,
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
              children: [
                _buildProgressIndicator(),
                const SizedBox(height: 16),
                _buildTahapAktif(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      color: AppColors.primaryBlue,
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
            Expanded(
              child: const Text(
                'Cek Kecukupan Pakan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${_tahapAktif + 1}/3',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final stepTitles = ['Data Sapi', 'Komposisi Pakan', 'Hasil Evaluasi'];
    final labels = [
      'Data Sapi & Kebutuhan Nutrien',
      'Pemilihan & Komposisi Pakan',
      'Hasil & Evaluasi Kecukupan Pakan',
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (index) {
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
                                  color: isCompleted || isCurrent
                                      ? AppColors.primaryBlue
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
                            if (index < 2)
                              Expanded(
                                child: Container(
                                  height: 2.5,
                                  color: isCompleted
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
                      ? Icons.pets
                      : _tahapAktif == 1
                          ? Icons.inventory_2_outlined
                          : Icons.analytics_outlined,
                  size: 16,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tahap ${_tahapAktif + 1} dari 3: ${labels[_tahapAktif]}',
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

  Widget _buildTahapAktif() {
    switch (_tahapAktif) {
      case 0:
        return Column(
          children: [
            _buildFormInput(),
            const SizedBox(height: 16),
            _buildOutputSection(),
          ],
        );
      case 1:
        return _buildPemberianPakanSection();
      case 2:
        return _buildHasilEvaluasiSection();
    }
    return const SizedBox.shrink();
  }

  Widget _buildHasilEvaluasiSection() {
    if (_hasilEvaluasi == null) {
      return AppCard(
        child: Column(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 48,
              color: AppColors.accentOrange,
            ),
            const SizedBox(height: 12),
            const Text(
              'Hasil evaluasi belum tersedia',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan kembali ke tahap sebelumnya untuk mengisi pakan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textLight),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        EvaluasiKecukupanCard(
          hasil: _hasilEvaluasi!,
          initialExpanded: true,
        ),
        const SizedBox(height: 16),
        _buildRingkasanPakanTerpilih(),
      ],
    );
  }

  Widget _buildRingkasanPakanTerpilih() {
    final totalKg = _pemberianPakan.fold<double>(
      0,
      (sum, item) => sum + item.jumlahKg,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Komposisi Pakan Diberikan',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total: ${_format(totalKg)} kg',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 12),
          ..._pemberianPakan.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final feedColor = getFeedColor(idx);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: feedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.bahan.nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Text(
                    '${_format(item.jumlahKg)} kg',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    if (_tahapAktif == 0) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _lanjutTahap,
          child: const Text('Lanjut ke Komposisi Pakan'),
        ),
      );
    } else if (_tahapAktif == 1) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _kembaliTahap,
              child: const Text('Kembali'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _lanjutTahap,
              child: const Text('Hitung & Evaluasi'),
            ),
          ),
        ],
      );
    } else {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _kembaliTahap,
              child: const Text('Ubah Pakan'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Selesai'),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildFormInput() {
    return AppCard(
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Sapi', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Text(
              'Fisiologi Sapi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
              hintText: 'Contoh: 400',
              validator: _validasiBeratBadan,
            ),
            if (_fisiologi == FisiologiSapi.laktasi) ...[
              const SizedBox(height: 12),
              AppTextField(
                controller: _produksiSusuController,
                label: 'Produksi Susu',
                suffix: 'liter/ekor/hari',
                hintText: 'Contoh: 13',
                validator: _validasiProduksiSusu,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _lemakSusuController,
                label: '% Lemak Susu',
                suffix: '%',
                hintText: 'Contoh: 3,5',
                validator: _validasiLemakSusu,
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 15,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Tuliskan target persentase lemak susu.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              if (_warningLemakSusu != null) ...[
                const SizedBox(height: 6),
                _buildRangeWarning(_warningLemakSusu!),
              ],
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

    if (_fisiologi == FisiologiSapi.keringKandang &&
        _kebutuhanNutrien == null) {
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

  String _format(double value) {
    if (!IndonesianNumberFormatter.isSupportedMagnitude(value)) return '-';
    return IndonesianNumberFormatter.format(value, decimals: 2);
  }

  String _formatPersen(double value) {
    if (!IndonesianNumberFormatter.isSupportedMagnitude(value)) return '-';
    return IndonesianNumberFormatter.format(value, decimals: 1);
  }

  bool _nilaiValid(Iterable<double> values) => values.every(
    (value) =>
        IndonesianNumberFormatter.isSupportedMagnitude(value) && value >= 0,
  );

  bool _hasilNutrisiValid(HasilPerhitunganNutrisi hasil) => _nilaiValid([
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
  ]);

  Widget _buildKartuKebutuhan() {
    final kebutuhan = _kebutuhanNutrien!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Kebutuhan Nutrien',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.primaryBlue),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Standar: ${_labelFisiologi(_fisiologi)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildNutrientChip('BK', _format(kebutuhan.kebutuhanBkKg), 'kg'),
              _buildNutrientChip(
                  'PK', _format(kebutuhan.kebutuhanProteinKg), 'kg'),
              _buildNutrientChip(
                  'TDN', _format(kebutuhan.kebutuhanTdnKg), 'kg'),
              _buildNutrientChip(
                  'Ca', _format(kebutuhan.kebutuhanCaGram), 'g'),
              _buildNutrientChip(
                  'P', _format(kebutuhan.kebutuhanPGram), 'g'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientChip(String label, String value, String satuan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            satuan,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
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
            style: const TextStyle(height: 1.5),
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
                key: _pakanRowKeys[index],
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
    final kontribusi = KontribusiNutrisiBahanPakan.fromItem(item, index: index);
    final feedColor = getFeedColor(index);
    final isBahanValid =
        item.bahan.isValidForCalculation(requirePositiveBk: true);

    final nutrisiText = !isBahanValid
        ? 'Data tidak valid'
        : item.jumlahKg > 0
        ? 'BK: ${_format(kontribusi.bkKg)}  •  PK: ${_format(kontribusi.pkKg)}  •  TDN: ${_format(kontribusi.tdnKg)} kg'
        : 'BK: ${_formatPersen(item.bahan.bk)}%  •  PK: ${_formatPersen(item.bahan.protein)}%  •  TDN: ${_formatPersen(item.bahan.tdn)}%';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Dot + Label + Dropdown + Delete
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: feedColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${index + 1}.',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<BahanPakan>(
                  initialValue: item.bahan,
                  isExpanded: true,
                  isDense: true,
                  items: _semuaBahan.map((bahan) {
                    return DropdownMenuItem<BahanPakan>(
                      value: bahan,
                      child: Text(bahan.nama,
                          style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) _ubahBahanPakan(index, value);
                  },
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _hapusBahanPakan(index),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.errorRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Input Jumlah + Subtitle Nutrisi
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: item.jumlahKg == 0
                      ? ''
                      : IndonesianNumberFormatter.isSupportedMagnitude(
                              item.jumlahKg)
                          ? IndonesianNumberFormatter.format(item.jumlahKg,
                              decimals: 2)
                          : '',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '0',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        widthFactor: 1.0,
                        child: Text(
                          'kg',
                          style: TextStyle(
                            color:
                                AppColors.textLight.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 0,
                      minHeight: 0,
                    ),
                  ),
                  onChanged: (value) => _ubahJumlahPakan(index, value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nutrisiText,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: item.jumlahKg > 0 && isBahanValid
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: !isBahanValid
                        ? AppColors.errorRed
                        : item.jumlahKg > 0
                        ? AppColors.textDark
                        : AppColors.textLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
