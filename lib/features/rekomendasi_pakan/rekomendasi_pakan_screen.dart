import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/indonesian_number_formatter.dart';
import '../../core/models/status_perhitungan.dart';
import '../../core/widgets/app_sliver_header.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/bahan_pakan.dart';
import '../../data/models/fisiologi_sapi.dart';
import '../../data/models/kebutuhan_nutrien_sapi.dart';
import '../../data/sources/bahan_pakan_repository.dart';
import '../cek_kecukupan_pakan/logic/perhitungan_kebutuhan_nutrien.dart';
import 'logic/hasil_rekomendasi_pakan.dart';
import 'logic/nutrien_helper.dart';
import 'logic/perhitungan_rekomendasi_pakan.dart';

class RekomendasiPakanScreen extends StatefulWidget {
  final KebutuhanNutrienSapi? kebutuhanAwal;

  const RekomendasiPakanScreen({
    super.key,
    this.kebutuhanAwal,
    this.repository,
  });

  final BahanPakanRepository? repository;

  @override
  State<RekomendasiPakanScreen> createState() => _RekomendasiPakanScreenState();
}

class _RekomendasiPakanScreenState extends State<RekomendasiPakanScreen> {
  static const maxSelectedFeedsPerGroup = 4;

  final _formKey = GlobalKey<FormState>();
  late final BahanPakanRepository _repository;

  final TextEditingController _beratBadanController = TextEditingController();
  final TextEditingController _produksiSusuController = TextEditingController();
  final TextEditingController _lemakSusuController = TextEditingController();

  FisiologiSapi _fisiologi = FisiologiSapi.dara;
  bool _isLoading = true;
  String? _errorMessage;

  List<BahanPakan> _semuaBahan = [];
  List<BahanPakan?> _hijauanTerpilih = [];
  List<BahanPakan?> _konsentratTerpilih = [];
  final List<ValueKey<int>> _hijauanRowKeys = [];
  final List<ValueKey<int>> _konsentratRowKeys = [];
  int _nextFeedRowKey = 0;

  KebutuhanNutrienSapi? _kebutuhanNutrien;
  HasilRekomendasiPakan? _hasilRekomendasi;
  StatusPerhitungan _statusPerhitungan = StatusPerhitungan.belumDihitung;
  String? _pesanPerhitungan;
  int _tahapAktif = 0;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BahanPakanRepository();
    _kebutuhanNutrien = _validasiKebutuhan(widget.kebutuhanAwal);
    _beratBadanController.addListener(_perbaruiPreviewKebutuhan);
    _produksiSusuController.addListener(_perbaruiPreviewKebutuhan);
    _lemakSusuController.addListener(_perbaruiPreviewKebutuhan);
    _muatBahanPakan();
  }

  @override
  void dispose() {
    _beratBadanController.removeListener(_perbaruiPreviewKebutuhan);
    _produksiSusuController.removeListener(_perbaruiPreviewKebutuhan);
    _lemakSusuController.removeListener(_perbaruiPreviewKebutuhan);
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
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat bahan pakan: $e';
        _isLoading = false;
      });
    }
  }

  void _perbaruiPreviewKebutuhan() {
    final kebutuhan = _hitungKebutuhanDariForm();
    if (!mounted) return;
    setState(() {
      _kebutuhanNutrien = kebutuhan;
      _hasilRekomendasi = null;
      _statusPerhitungan = StatusPerhitungan.belumDihitung;
      _pesanPerhitungan =
          kebutuhan == null &&
              (_beratBadanController.text.trim().isNotEmpty ||
                  _produksiSusuController.text.trim().isNotEmpty ||
                  _lemakSusuController.text.trim().isNotEmpty)
          ? 'Target kebutuhan nutrien tidak valid.'
          : null;
    });
  }

  List<BahanPakan> get _opsiHijauan =>
      _semuaBahan.where(isBahanHijauan).toList();
  List<BahanPakan> get _opsiKonsentrat =>
      _semuaBahan.where(isBahanKonsentrat).toList();

  List<BahanPakan> _opsiHijauanUntuk(int index) {
    final selectedIds = <int>{
      ..._hijauanTerpilih
          .asMap()
          .entries
          .where((entry) => entry.key != index)
          .map((entry) => entry.value?.id)
          .whereType<int>(),
      ..._konsentratTerpilih.map((item) => item?.id).whereType<int>(),
    };
    final currentId = _hijauanTerpilih[index]?.id;
    return _opsiHijauan
        .where((item) => item.id == currentId || !selectedIds.contains(item.id))
        .toList();
  }

  List<BahanPakan> _opsiKonsentratUntuk(int index) {
    final selectedIds = <int>{
      ..._konsentratTerpilih
          .asMap()
          .entries
          .where((entry) => entry.key != index)
          .map((entry) => entry.value?.id)
          .whereType<int>(),
      ..._hijauanTerpilih.map((item) => item?.id).whereType<int>(),
    };
    final currentId = _konsentratTerpilih[index]?.id;
    return _opsiKonsentrat
        .where((item) => item.id == currentId || !selectedIds.contains(item.id))
        .toList();
  }

  void _invalidasiRekomendasi() {
    _hasilRekomendasi = null;
    _statusPerhitungan = StatusPerhitungan.belumDihitung;
    _pesanPerhitungan = null;
  }

  void _ubahFisiologi(FisiologiSapi? value) {
    if (value == null) return;
    setState(() {
      _fisiologi = value;
      _invalidasiRekomendasi();
      if (_fisiologi != FisiologiSapi.laktasi) {
        _produksiSusuController.clear();
        _lemakSusuController.clear();
      }
    });
    _perbaruiPreviewKebutuhan();
  }

  void _gunakanDataCekKecukupan() {
    if (widget.kebutuhanAwal == null) {
      _showSnackBar('Data Cek Kecukupan Pakan belum tersedia.');
      return;
    }

    setState(() {
      _beratBadanController.clear();
      _produksiSusuController.clear();
      _lemakSusuController.clear();
      _kebutuhanNutrien = _validasiKebutuhan(widget.kebutuhanAwal);
      _invalidasiRekomendasi();
    });
  }

  void _tambahHijauan() {
    if (_hijauanTerpilih.length >= maxSelectedFeedsPerGroup) {
      _showSnackBar('Maksimal $maxSelectedFeedsPerGroup bahan hijauan.');
      return;
    }
    setState(() {
      _hijauanTerpilih = [..._hijauanTerpilih, null];
      _hijauanRowKeys.add(ValueKey(_nextFeedRowKey++));
      _invalidasiRekomendasi();
    });
  }

  void _tambahKonsentrat() {
    if (_konsentratTerpilih.length >= maxSelectedFeedsPerGroup) {
      _showSnackBar('Maksimal $maxSelectedFeedsPerGroup bahan konsentrat.');
      return;
    }
    setState(() {
      _konsentratTerpilih = [..._konsentratTerpilih, null];
      _konsentratRowKeys.add(ValueKey(_nextFeedRowKey++));
      _invalidasiRekomendasi();
    });
  }

  void _hapusHijauan(int index) {
    setState(() {
      _hijauanTerpilih = List.of(_hijauanTerpilih)..removeAt(index);
      _hijauanRowKeys.removeAt(index);
      _invalidasiRekomendasi();
    });
  }

  void _hapusKonsentrat(int index) {
    setState(() {
      _konsentratTerpilih = List.of(_konsentratTerpilih)..removeAt(index);
      _konsentratRowKeys.removeAt(index);
      _invalidasiRekomendasi();
    });
  }

  void _ubahHijauan(int index, BahanPakan? value) {
    if (value == null) return;
    final duplikatKelompok = _hijauanTerpilih.asMap().entries.any((entry) {
      return entry.key != index && entry.value?.id == value.id;
    });
    final duplikatLintasKelompok = _konsentratTerpilih.any(
      (item) => item?.id == value.id,
    );

    if (duplikatKelompok || duplikatLintasKelompok) {
      AppToast.showWarning(context, 'Bahan pakan tersebut sudah dipilih.');
      return;
    }

    setState(() {
      _hijauanTerpilih[index] = value;
      _invalidasiRekomendasi();
    });
  }

  void _ubahKonsentrat(int index, BahanPakan? value) {
    if (value == null) return;
    final duplikatKelompok = _konsentratTerpilih.asMap().entries.any((entry) {
      return entry.key != index && entry.value?.id == value.id;
    });
    final duplikatLintasKelompok = _hijauanTerpilih.any(
      (item) => item?.id == value.id,
    );

    if (duplikatKelompok || duplikatLintasKelompok) {
      AppToast.showWarning(context, 'Bahan pakan tersebut sudah dipilih.');
      return;
    }

    setState(() {
      _konsentratTerpilih[index] = value;
      _invalidasiRekomendasi();
    });
  }

  void _hitungRekomendasi() {
    final kebutuhan = _hitungKebutuhanDariForm();
    if (kebutuhan == null) {
      _gagalMenghitung('Lengkapi kebutuhan nutrien sapi terlebih dahulu.');
      return;
    }

    if (_repository.semuaData.any((bahan) => !bahan.isValidForCalculation())) {
      _gagalMenghitung(
        'Data bahan pakan tersimpan tidak valid. Periksa nilai nutrisi, harga, dan BK.',
      );
      return;
    }

    final hijauan = _hijauanTerpilih.whereType<BahanPakan>().toList();
    final konsentrat = _konsentratTerpilih.whereType<BahanPakan>().toList();

    if (hijauan.isEmpty) {
      _gagalMenghitung('Tambahkan minimal satu hijauan.');
      return;
    }

    if (konsentrat.isEmpty) {
      _gagalMenghitung('Tambahkan minimal satu konsentrat.');
      return;
    }

    if (_hijauanTerpilih.any((item) => item == null) ||
        _konsentratTerpilih.any((item) => item == null)) {
      _gagalMenghitung('Lengkapi semua pilihan bahan pakan terlebih dahulu.');
      return;
    }

    final semuaBahan = [...hijauan, ...konsentrat];
    final adaBkKosong = semuaBahan.any((item) => item.bk <= 0);
    if (adaBkKosong) {
      _gagalMenghitung(
        'Semua bahan pakan harus memiliki nilai BK lebih dari 0.',
      );
      return;
    }

    try {
      final hasil = PerhitunganRekomendasiPakan.hitung(
        kebutuhan: kebutuhan,
        bahanHijauan: hijauan,
        bahanKonsentrat: konsentrat,
      );

      if (!_hasilRekomendasiValid(hasil)) {
        _gagalMenghitung('Hasil rekomendasi pakan tidak valid.');
        return;
      }

      setState(() {
        _kebutuhanNutrien = kebutuhan;
        _hasilRekomendasi = hasil;
        _statusPerhitungan = StatusPerhitungan.berhasil;
        _pesanPerhitungan = null;
      });

      if (!hasil.isLkAman) {
        AppToast.showWarning(context, 'LK melebihi batas 5% BK.');
      }
    } catch (_) {
      _gagalMenghitung('Rekomendasi pakan gagal dihitung.');
    }
  }

  void _gagalMenghitung(String pesan) {
    setState(() {
      _hasilRekomendasi = null;
      _statusPerhitungan = StatusPerhitungan.gagal;
      _pesanPerhitungan = pesan;
    });
    if (mounted) {
      AppToast.showError(context, pesan, title: 'Perhitungan Gagal');
    }
  }

  bool _validasiTahapSatu() {
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return false;
    return _hitungKebutuhanDariForm() != null;
  }

  bool _validasiTahapDua() {
    if (_kebutuhanNutrien == null) {
      _gagalMenghitung('Lengkapi Data Sapi terlebih dahulu.');
      return false;
    }

    if (_repository.semuaData.any((bahan) => !bahan.isValidForCalculation())) {
      _gagalMenghitung(
        'Data bahan pakan tersimpan tidak valid. Periksa nilai nutrisi, harga, dan BK.',
      );
      return false;
    }

    if (_hijauanTerpilih.length > maxSelectedFeedsPerGroup) {
      _gagalMenghitung('Maksimal $maxSelectedFeedsPerGroup bahan hijauan.');
      return false;
    }
    if (_konsentratTerpilih.length > maxSelectedFeedsPerGroup) {
      _gagalMenghitung('Maksimal $maxSelectedFeedsPerGroup bahan konsentrat.');
      return false;
    }

    if (_hijauanTerpilih.isEmpty) {
      _gagalMenghitung('Tambahkan minimal satu hijauan.');
      return false;
    }
    if (_konsentratTerpilih.isEmpty) {
      _gagalMenghitung('Tambahkan minimal satu konsentrat.');
      return false;
    }
    if (_hijauanTerpilih.any((item) => item == null) ||
        _konsentratTerpilih.any((item) => item == null)) {
      _gagalMenghitung('Lengkapi semua pilihan bahan pakan terlebih dahulu.');
      return false;
    }

    final hijauan = _hijauanTerpilih.whereType<BahanPakan>().toList();
    final konsentrat = _konsentratTerpilih.whereType<BahanPakan>().toList();
    if (!hijauan.any(isBahanHijauan)) {
      _gagalMenghitung(
        'Pilihan bahan hijauan harus memiliki pakan dengan kategori hijauan.',
      );
      return false;
    }
    if (!konsentrat.any(isBahanKonsentrat)) {
      _gagalMenghitung(
        'Pilihan bahan konsentrat harus memiliki pakan dengan kategori konsentrat.',
      );
      return false;
    }

    final semuaBahan = [...hijauan, ...konsentrat];
    final adaBkKosong = semuaBahan.any((item) => item.bk <= 0);
    if (adaBkKosong) {
      _gagalMenghitung(
        'Semua bahan pakan harus memiliki nilai BK lebih dari 0.',
      );
      return false;
    }
    return true;
  }

  void _lanjutTahap() {
    if (_tahapAktif == 0) {
      if (_validasiTahapSatu()) {
        setState(() => _tahapAktif = 1);
        if (_warningLemakSusu != null) {
          AppToast.showWarning(
            context,
            _warningLemakSusu!,
            title: 'Peringatan Lemak Susu',
          );
        } else {
          AppToast.showSuccess(
            context,
            'Data sapi tersimpan. Silakan pilih bahan pakan.',
            title: 'Data Sapi Siap',
          );
        }
      } else {
        AppToast.showWarning(
          context,
          'Lengkapi data sapi terlebih dahulu.',
          title: 'Data Belum Lengkap',
        );
      }
      return;
    }

    if (_tahapAktif == 1 && _validasiTahapDua()) {
      _hitungRekomendasi();
      if (_statusPerhitungan == StatusPerhitungan.berhasil) {
        setState(() => _tahapAktif = 2);
        AppToast.showSuccess(
          context,
          'Formulasi rekomendasi pakan berhasil dihitung!',
          title: 'Rekomendasi Siap',
        );
      }
    }
  }

  void _kembaliTahap() {
    if (_tahapAktif == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _tahapAktif--);
  }

  bool get _hasEnteredData =>
      _beratBadanController.text.trim().isNotEmpty ||
      _produksiSusuController.text.trim().isNotEmpty ||
      _lemakSusuController.text.trim().isNotEmpty ||
      _hijauanTerpilih.isNotEmpty ||
      _konsentratTerpilih.isNotEmpty;

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

  KebutuhanNutrienSapi? _hitungKebutuhanDariForm() {
    if (widget.kebutuhanAwal != null &&
        _beratBadanController.text.trim().isEmpty &&
        _produksiSusuController.text.trim().isEmpty &&
        _lemakSusuController.text.trim().isEmpty) {
      return _validasiKebutuhan(widget.kebutuhanAwal);
    }

    final beratBadan = _parseDouble(_beratBadanController.text);
    final produksiSusu = _parseDouble(_produksiSusuController.text);
    final lemakSusu = _parseDouble(_lemakSusuController.text);

    if (beratBadan <= 0) return null;
    if (_fisiologi == FisiologiSapi.laktasi &&
        (produksiSusu <= 0 || lemakSusu <= 0)) {
      return null;
    }

    try {
      final kebutuhan = PerhitunganKebutuhanNutrien.hitungKebutuhan(
        fisiologi: _fisiologi,
        beratBadan: beratBadan,
        produksiSusuLiter: _fisiologi == FisiologiSapi.laktasi
            ? produksiSusu
            : null,
        lemakSusuPersen: _fisiologi == FisiologiSapi.laktasi ? lemakSusu : null,
      );
      return _validasiKebutuhan(kebutuhan);
    } catch (_) {
      return null;
    }
  }

  KebutuhanNutrienSapi? _validasiKebutuhan(KebutuhanNutrienSapi? kebutuhan) {
    if (kebutuhan == null) return null;
    final nilai = [
      kebutuhan.kebutuhanBkKg,
      kebutuhan.kebutuhanProteinKg,
      kebutuhan.kebutuhanTdnKg,
      kebutuhan.kebutuhanCaGram,
      kebutuhan.kebutuhanPGram,
    ];
    if (nilai.any(
      (item) =>
          !IndonesianNumberFormatter.isSupportedMagnitude(item) || item < 0,
    )) {
      return null;
    }
    return kebutuhan;
  }

  String? get _warningLemakSusu {
    if (_fisiologi != FisiologiSapi.laktasi) return null;
    final val = _parseDouble(_lemakSusuController.text);
    if (val <= 0) return null;
    if (val < 2.5) return 'Lemak terlalu rendah (< 2,5%)';
    if (val > 4.0) return 'Lemak terlalu tinggi (> 4,0%)';
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

  double _parseDouble(String value) {
    final parsed = IndonesianNumberFormatter.tryParse(value)?.toDouble();
    return parsed != null &&
            IndonesianNumberFormatter.isSupportedMagnitude(parsed)
        ? parsed
        : 0;
  }

  String _format(double value) =>
      IndonesianNumberFormatter.format(value, decimals: 2);

  bool _nilaiValid(Iterable<double> values) => values.every(
    (value) =>
        IndonesianNumberFormatter.isSupportedMagnitude(value) && value >= 0,
  );

  bool _hasilRekomendasiValid(HasilRekomendasiPakan hasil) {
    final nilai = [
      hasil.kebutuhan.bkKg,
      hasil.kebutuhan.pkKg,
      hasil.kebutuhan.tdnKg,
      hasil.kebutuhan.caGram,
      hasil.kebutuhan.pGram,
      hasil.targetBkHijauan,
      hasil.targetBkKonsentrat,
      hasil.totalHijauan.bkKg,
      hasil.totalHijauan.pkKg,
      hasil.totalHijauan.tdnKg,
      hasil.totalHijauan.caGram,
      hasil.totalHijauan.pGram,
      hasil.totalHijauan.abuKg,
      hasil.totalHijauan.lkKg,
      hasil.totalHijauan.skKg,
      hasil.totalHijauan.betnKg,
      hasil.totalKonsentrat.bkKg,
      hasil.totalKonsentrat.pkKg,
      hasil.totalKonsentrat.tdnKg,
      hasil.totalKonsentrat.caGram,
      hasil.totalKonsentrat.pGram,
      hasil.totalKonsentrat.abuKg,
      hasil.totalKonsentrat.lkKg,
      hasil.totalKonsentrat.skKg,
      hasil.totalKonsentrat.betnKg,
      hasil.totalGabungan.bkKg,
      hasil.totalGabungan.pkKg,
      hasil.totalGabungan.tdnKg,
      hasil.totalGabungan.caGram,
      hasil.totalGabungan.pGram,
      hasil.totalGabungan.abuKg,
      hasil.totalGabungan.lkKg,
      hasil.totalGabungan.skKg,
      hasil.totalGabungan.betnKg,
      hasil.lkPersenDariBk,
      ...hasil.rekomendasiHijauan.expand(
        (item) => [
          item.asFedKg,
          item.bkKg,
          item.kontribusi.bkKg,
          item.kontribusi.pkKg,
          item.kontribusi.tdnKg,
          item.kontribusi.caGram,
          item.kontribusi.pGram,
          item.kontribusi.abuKg,
          item.kontribusi.lkKg,
          item.kontribusi.skKg,
          item.kontribusi.betnKg,
        ],
      ),
      ...hasil.rekomendasiKonsentrat.expand(
        (item) => [
          item.asFedKg,
          item.bkKg,
          item.kontribusi.bkKg,
          item.kontribusi.pkKg,
          item.kontribusi.tdnKg,
          item.kontribusi.caGram,
          item.kontribusi.pGram,
          item.kontribusi.abuKg,
          item.kontribusi.lkKg,
          item.kontribusi.skKg,
          item.kontribusi.betnKg,
        ],
      ),
    ];
    return _nilaiValid(nilai);
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
    if (value == null || value.trim().isEmpty) return 'BB wajib diisi';
    final parsed = IndonesianNumberFormatter.tryParse(value)?.toDouble();
    if (parsed == null ||
        !IndonesianNumberFormatter.isSupportedMagnitude(parsed)) {
      return 'Angka tidak valid';
    }
    if (parsed <= 0) return 'BB harus lebih dari 0';
    return null;
  }

  String? _validasiProduksiSusu(String? value) {
    if (_fisiologi != FisiologiSapi.laktasi) return null;
    if (value == null || value.trim().isEmpty) {
      return 'Produksi susu wajib diisi';
    }
    final parsed = IndonesianNumberFormatter.tryParse(value)?.toDouble();
    if (parsed == null ||
        !IndonesianNumberFormatter.isSupportedMagnitude(parsed)) {
      return 'Angka tidak valid';
    }
    if (parsed <= 0) return 'Produksi susu harus lebih dari 0';
    return null;
  }

  String? _validasiLemakSusu(String? value) {
    if (_fisiologi != FisiologiSapi.laktasi) return null;
    if (value == null || value.trim().isEmpty) return 'Lemak susu wajib diisi';
    final parsed = IndonesianNumberFormatter.tryParse(value)?.toDouble();
    if (parsed == null ||
        !IndonesianNumberFormatter.isSupportedMagnitude(parsed)) {
      return 'Angka tidak valid';
    }
    if (parsed <= 0) return 'Lemak susu harus lebih dari 0';
    return null;
  }

  Widget _buildStatusPerhitungan() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gagal menghitung',
            style: TextStyle(
              color: AppColors.errorRed,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_pesanPerhitungan != null) ...[
            const SizedBox(height: 4),
            Text(
              _pesanPerhitungan!,
              style: const TextStyle(color: AppColors.errorRed),
            ),
          ],
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    AppToast.showWarning(context, message);
  }

  double _hitungTotalAsFed(List<RekomendasiPakanItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.asFedKg);
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
        bottomNavigationBar: !_isLoading && _errorMessage == null
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _buildNavigationControls(),
                ),
              )
            : null,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_errorMessage!, textAlign: TextAlign.center),
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
                        title: 'Rekomendasi Pakan',
                        subtitle: 'Dapatkan rekomendasi pakan sesuai kebutuhan sapi.',
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
    const labels = ['Data Sapi', 'Bahan Pakan Tersedia', 'Hasil Rekomendasi'];

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
              child: Text(
                'Tahap ${_tahapAktif + 1} · ${labels[_tahapAktif]}',
                style: const TextStyle(
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
    const labels = ['Data Sapi', 'Bahan Pakan Tersedia', 'Hasil Rekomendasi'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tahap ${_tahapAktif + 1} dari ${labels.length}',
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(labels[_tahapAktif]),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_tahapAktif + 1) / labels.length,
            minHeight: 8,
            borderRadius: BorderRadius.circular(8),
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
            _buildProfilCard(),
            if (_pesanPerhitungan != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _pesanPerhitungan!,
                  style: const TextStyle(color: AppColors.errorRed),
                ),
              ),
            ],
          ],
        );
      case 1:
        return Column(
          children: [
            if (_kebutuhanNutrien != null) ...[
              _buildTargetBkPakanCard(_kebutuhanNutrien!),
              const SizedBox(height: 16),
            ],
            _buildFeedSelectionCard(
              title: 'Hijauan yang Dimiliki',
              subtitle:
                  'Pilih bahan hijauan yang tersedia. Jumlah kg akan dihitung otomatis.',
              icon: Icons.grass_rounded,
              accentColor: const Color(0xFFB9E7C9),
              avatarColor: const Color(0xFFDFF5E7),
              items: _hijauanTerpilih,
              rowKeys: _hijauanRowKeys,
              opsiForIndex: _opsiHijauanUntuk,
              onAdd: _tambahHijauan,
              onRemove: _hapusHijauan,
              onChanged: _ubahHijauan,
              buttonLabel: 'Tambah Hijauan',
              emptyTitle: 'Belum ada hijauan yang dipilih.',
              emptyIcon: Icons.park_outlined,
            ),
            const SizedBox(height: 16),
            _buildFeedSelectionCard(
              title: 'Konsentrat yang Dimiliki',
              subtitle:
                  'Pilih bahan konsentrat yang tersedia. Sistem akan melakukan pencarian kombinasi terbaik.',
              icon: Icons.inventory_2_outlined,
              accentColor: const Color(0xFFF7D8A8),
              avatarColor: const Color(0xFFFFEBD1),
              items: _konsentratTerpilih,
              rowKeys: _konsentratRowKeys,
              opsiForIndex: _opsiKonsentratUntuk,
              onAdd: _tambahKonsentrat,
              onRemove: _hapusKonsentrat,
              onChanged: _ubahKonsentrat,
              buttonLabel: 'Tambah Konsentrat',
              emptyTitle: 'Belum ada konsentrat yang dipilih.',
              emptyIcon: Icons.food_bank_outlined,
            ),
            if (_statusPerhitungan == StatusPerhitungan.gagal) ...[
              const SizedBox(height: 12),
              _buildStatusPerhitungan(),
            ],
          ],
        );
      case 2:
        return _hasilRekomendasi == null
            ? _buildSectionCard(
                title: 'Hasil Rekomendasi',
                icon: Icons.auto_awesome_rounded,
                child: Text(
                  _pesanPerhitungan ??
                      'Lengkapi tahap sebelumnya untuk melihat hasil rekomendasi.',
                ),
              )
            : _buildRecommendationResult();
    }
    return const SizedBox.shrink();
  }

  Widget _buildNavigationControls() {
    if (_tahapAktif == 2) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: FilledButton(onPressed: _lanjutTahap, child: const Text('Lanjut')),
    );
  }

  Widget _buildRecommendationResult() {
    final hasil = _hasilRekomendasi!;
    final totalAsFed =
        _hitungTotalAsFed(hasil.rekomendasiHijauan) +
        _hitungTotalAsFed(hasil.rekomendasiKonsentrat);
    final total = hasil.totalGabungan;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          title: 'Hasil Rekomendasi',
          icon: Icons.auto_awesome_rounded,
          subtitle:
              'Proporsi pemberian pakan harian per ekor sapi berdasarkan target fisiologi.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    color: AppColors.expertPurple,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Hasil Analisis Ransum Pakan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: AppColors.secondaryGreen,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Optimal',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildCombinedRecommendationCard(hasil),
              const SizedBox(height: 14),
              _buildTotalAsFedBox(totalAsFed, total.bkKg),
              const SizedBox(height: 14),
              _buildLkSafetyBanner(hasil),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _tampilkanDetailEvaluasiModal(hasil),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.expertPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.analytics_outlined, size: 20),
                  label: const Text(
                    'Lihat Detail Evaluasi Nutrisi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _tahapAktif = 1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Sesuaikan Pakan / Hitung Ulang'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _tampilkanDetailEvaluasiModal(HasilRekomendasiPakan hasil) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      color: AppColors.expertPurple,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Detail Evaluasi Nutrisi Ransum',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('close_detail_evaluasi_btn'),
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildTotalSummaryCard(hasil),
                    const SizedBox(height: 16),
                    _buildEvaluationCard(hasil),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppColors.secondaryGreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textLight,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildProfilCard() {
    return _buildSectionCard(
      title: 'Data Sapi',
      icon: Icons.pets_outlined,
      subtitle:
          'Isi profil sapi atau gunakan data dari Cek Kecukupan untuk menampilkan kebutuhan nutrien.',
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFieldLabel('Fisiologi Sapi'),
            const SizedBox(height: 8),
            DropdownButtonFormField<FisiologiSapi>(
              initialValue: _fisiologi,
              hint: const Text('-- Pilih Fisiologi --'),
              decoration: _dropdownDecoration(),
              items: FisiologiSapi.values.map((fisiologi) {
                return DropdownMenuItem<FisiologiSapi>(
                  value: fisiologi,
                  child: Text(_labelFisiologi(fisiologi)),
                );
              }).toList(),
              onChanged: _ubahFisiologi,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: _beratBadanController,
              label: 'BB Sapi',
              suffix: 'kg',
              validator: _validasiBeratBadan,
              hintText: 'Contoh: 400',
            ),
            if (_fisiologi == FisiologiSapi.laktasi) ...[
              const SizedBox(height: 14),
              AppTextField(
                controller: _produksiSusuController,
                label: 'Produksi Susu',
                suffix: 'liter/ekor/hari',
                validator: _validasiProduksiSusu,
                hintText: 'Contoh: 13',
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _lemakSusuController,
                label: '% Lemak Susu',
                suffix: '%',
                validator: _validasiLemakSusu,
                hintText: 'Contoh: 3,5',
                onFieldSubmitted: (_) {
                  if (_warningLemakSusu != null) {
                    AppToast.showWarning(
                      context,
                      _warningLemakSusu!,
                      title: 'Peringatan Lemak Susu',
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tuliskan target lemak susu.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                        height: 1.4,
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
            if (widget.kebutuhanAwal != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _gunakanDataCekKecukupan,
                icon: const Icon(Icons.sync_alt_outlined),
                label: const Text('Gunakan Data Cek Kecukupan Pakan'),
              ),
            ],
            if (_kebutuhanNutrien != null) ...[
              const Divider(height: 32),
              Row(
                children: [
                  const Text(
                    'Kebutuhan Nutrien',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  _buildNutrientChip(
                    'BK',
                    _format(_kebutuhanNutrien!.kebutuhanBkKg),
                    'kg',
                  ),
                  _buildNutrientChip(
                    'PK',
                    _format(_kebutuhanNutrien!.kebutuhanProteinKg),
                    'kg',
                  ),
                  _buildNutrientChip(
                    'TDN',
                    _format(_kebutuhanNutrien!.kebutuhanTdnKg),
                    'kg',
                  ),
                  _buildNutrientChip(
                    'Ca',
                    _format(_kebutuhanNutrien!.kebutuhanCaGram),
                    'g',
                  ),
                  _buildNutrientChip(
                    'P',
                    _format(_kebutuhanNutrien!.kebutuhanPGram),
                    'g',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTargetBkPakanCard(KebutuhanNutrienSapi kebutuhan) {
    final targetHijauan = kebutuhan.kebutuhanBkKg * 0.60;
    final targetKonsentrat = kebutuhan.kebutuhanBkKg * 0.40;

    return _buildSectionCard(
      title: 'Target BK Pakan',
      icon: Icons.pie_chart_outline_rounded,
      child: Row(
        children: [
          Expanded(
            child: _buildColoredMiniCard(
              title: 'Hijauan',
              value: '${_format(targetHijauan)} kg BK',
              badge: '60%',
              background: const Color(0xFFE8F7EC),
              textColor: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildColoredMiniCard(
              title: 'Konsentrat',
              value: '${_format(targetKonsentrat)} kg BK',
              badge: '40%',
              background: const Color(0xFFFFF1DE),
              textColor: const Color(0xFFC77700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color avatarColor,
    required List<BahanPakan?> items,
    required List<ValueKey<int>> rowKeys,
    required List<BahanPakan> Function(int index) opsiForIndex,
    required VoidCallback onAdd,
    required void Function(int index) onRemove,
    required void Function(int index, BahanPakan? value) onChanged,
    required String buttonLabel,
    required String emptyTitle,
    required IconData emptyIcon,
  }) {
    return _buildSectionCard(
      title: title,
      icon: icon,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (items.isEmpty)
            _buildEmptyState(
              icon: emptyIcon,
              title: emptyTitle,
              subtitle:
                  'Tambahkan bahan untuk mulai menghitung rekomendasi otomatis.',
            )
          else
            ...List.generate(
              items.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == items.length - 1 ? 0 : 12,
                ),
                child: _buildFeedSelectionItem(
                  key: rowKeys[index],
                  index: index,
                  item: items[index],
                  opsi: opsiForIndex(index),
                  onRemove: () => onRemove(index),
                  onChanged: (value) => onChanged(index, value),
                  avatarColor: avatarColor,
                  accentColor: accentColor,
                ),
              ),
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedSelectionItem({
    required Key key,
    required int index,
    required BahanPakan? item,
    required List<BahanPakan> opsi,
    required VoidCallback onRemove,
    required void Function(BahanPakan? value) onChanged,
    required Color avatarColor,
    required Color accentColor,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: avatarColor,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pilih bahan pakan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.errorRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<BahanPakan>(
            initialValue: item,
            isExpanded: true,
            decoration: _dropdownDecoration(),
            hint: const Text('Pilih bahan pakan'),
            items: opsi.map((bahan) {
              return DropdownMenuItem<BahanPakan>(
                value: bahan,
                child: Text(bahan.nama, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: onChanged,
          ),
          if (item != null) ...[
            const SizedBox(height: 12),
            if (!item.isValidForCalculation(requirePositiveBk: true))
              const Text(
                'Data bahan pakan tidak valid.',
                style: TextStyle(color: AppColors.errorRed),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInfoChip('BK ${_format(item.bk)}%'),
                  _buildInfoChip('PK ${_format(item.protein)}%'),
                  _buildInfoChip('TDN ${_format(item.tdn)}%'),
                  _buildInfoChip('LK ${_format(item.lemak)}%'),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildCombinedRecommendationCard(HasilRekomendasiPakan hasil) {
    final hijauan = hasil.rekomendasiHijauan;
    final konsentrat = hasil.rekomendasiKonsentrat;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-bagian Hijauan
          Row(
            children: [
              const Icon(
                Icons.grass_rounded,
                color: AppColors.secondaryGreen,
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'Hijauan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (hijauan.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Tidak ada rekomendasi hijauan.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            )
          else
            ...hijauan.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildRecommendationItem(
                  item: item,
                  tint: AppColors.secondaryGreen.withValues(alpha: 0.08),
                  accent: AppColors.secondaryGreen,
                ),
              ),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),

          // Sub-bagian Konsentrat
          Row(
            children: [
              const Icon(
                Icons.restaurant_menu_outlined,
                color: AppColors.accentOrange,
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'Konsentrat',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (konsentrat.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Tidak ada rekomendasi konsentrat.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            )
          else
            ...konsentrat.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildRecommendationItem(
                  item: item,
                  tint: AppColors.accentOrange.withValues(alpha: 0.08),
                  accent: AppColors.accentOrange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem({
    required RekomendasiPakanItem item,
    required Color tint,
    required Color accent,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'BK: ${_format(item.bkKg)} kg',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_format(item.asFedKg)} kg',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
              const Text(
                'per ekor/hari',
                style: TextStyle(fontSize: 11, color: AppColors.textGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAsFedBox(double totalAsFed, double totalBk) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.scale_rounded,
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Pemberian Pakan (As Fed)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_format(totalAsFed)} kg/ekor/hari',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              'Total BK: ${_format(totalBk)} kg',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLkSafetyBanner(HasilRekomendasiPakan hasil) {
    final isAman = hasil.isLkAman;
    final color = isAman ? AppColors.secondaryGreen : AppColors.accentOrange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isAman ? Icons.verified_outlined : Icons.warning_amber_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAman
                      ? 'Evaluasi Lemak Kasar (LK): Memenuhi Standar'
                      : 'Peringatan: Lemak Kasar (LK) Perlu Penyesuaian',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isAman
                      ? 'Kandungan Lemak Kasar (LK) memenuhi batas standar (< 5% BK) yaitu ${_format(hasil.lkPersenDariBk)}% dari total Bahan Kering (BK).'
                      : 'Kandungan Lemak Kasar (LK) melebihi batas toleransi 5% yaitu ${_format(hasil.lkPersenDariBk)}% dari total Bahan Kering (BK). Disarankan untuk mengurangi proporsi bahan kaya lemak.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSummaryCard(HasilRekomendasiPakan hasil) {
    final total = hasil.totalGabungan;
    final totalAsFed =
        _hitungTotalAsFed(hasil.rekomendasiHijauan) +
        _hitungTotalAsFed(hasil.rekomendasiKonsentrat);

    return _buildSectionCard(
      title: 'Total Hijauan + Konsentrat',
      icon: Icons.summarize_outlined,
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: [
          _buildNutrientMiniCard(
            'Total As Fed',
            '${_format(totalAsFed)} kg/ekor/hari',
          ),
          _buildNutrientMiniCard('Total BK', '${_format(total.bkKg)} kg'),
          _buildNutrientMiniCard('Total PK', '${_format(total.pkKg)} kg'),
          _buildNutrientMiniCard('Total TDN', '${_format(total.tdnKg)} kg'),
          _buildNutrientMiniCard('Total Ca', '${_format(total.caGram)} gram'),
          _buildNutrientMiniCard('Total P', '${_format(total.pGram)} gram'),
          _buildNutrientMiniCard(
            'LK',
            '${_format(hasil.lkPersenDariBk)}% dari BK',
          ),
          _buildNutrientMiniCard('LK Total', '${_format(total.lkKg)} kg'),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard(HasilRekomendasiPakan hasil) {
    final total = hasil.totalGabungan;

    return _buildSectionCard(
      title: 'Evaluasi Terhadap Target',
      icon: Icons.analytics_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEvaluationItem(
            label: 'BK',
            hasilValue: total.bkKg,
            target: hasil.kebutuhan.bkKg,
            unit: 'kg',
          ),
          _buildEvaluationItem(
            label: 'PK',
            hasilValue: total.pkKg,
            target: hasil.kebutuhan.pkKg,
            unit: 'kg',
          ),
          _buildEvaluationItem(
            label: 'TDN',
            hasilValue: total.tdnKg,
            target: hasil.kebutuhan.tdnKg,
            unit: 'kg',
          ),
          _buildEvaluationItem(
            label: 'Ca',
            hasilValue: total.caGram,
            target: hasil.kebutuhan.caGram,
            unit: 'gram',
          ),
          _buildEvaluationItem(
            label: 'P',
            hasilValue: total.pGram,
            target: hasil.kebutuhan.pGram,
            unit: 'gram',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.expertPurple, // High-intensity brand purple
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.expertPurple.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hasil.isLkAman
                      ? Icons.verified_outlined
                      : Icons.warning_amber_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasil.isLkAman
                            ? 'Evaluasi Lemak Kasar (LK): Memenuhi Standar'
                            : 'Peringatan: Lemak Kasar (LK) Perlu Penyesuaian',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasil.isLkAman
                            ? 'Kandungan Lemak Kasar (LK) memenuhi batas standar (< 5% BK) yaitu ${_format(hasil.lkPersenDariBk)}% dari total Bahan Kering (BK).'
                            : 'Kandungan Lemak Kasar (LK) melebihi batas toleransi 5% yaitu ${_format(hasil.lkPersenDariBk)}% dari total Bahan Kering (BK). Disarankan untuk mengurangi proporsi bahan kaya lemak seperti bungkil kelapa atau polar.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!hasil.hasCaData || !hasil.hasPData) ...[
            const SizedBox(height: 12),
            Text(
              'Catatan: sebagian bahan belum memiliki data Ca/P, sehingga nilai Ca dan P dapat masih terbaca 0.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textLight,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEvaluationItem({
    required String label,
    required double hasilValue,
    required double target,
    required String unit,
  }) {
    final status = NutrienHelper.statusNutrien(
      hasil: hasilValue,
      target: target,
    );
    String selisihText;
    if (status == 'Kurang') {
      selisihText = 'Kurang ${_format((target - hasilValue).abs())} $unit';
    } else if (status == 'Berlebih') {
      selisihText = 'Lebih ${_format((hasilValue - target).abs())} $unit';
    } else {
      selisihText = 'Sesuai kebutuhan';
    }
    final statusColor = status == 'Pas'
        ? AppColors.statusPas
        : status == 'Kurang'
        ? AppColors.statusKurang
        : AppColors.statusBerlebih;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_format(hasilValue)} / ${_format(target)} $unit',
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  selisihText,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientChip(String label, String value, String satuan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryBlue,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            satuan,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientMiniCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textGrey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColoredMiniCard({
    required String title,
    required String value,
    required String badge,
    required Color background,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textLight,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.textLight),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryGreen),
      ),
    );
  }
}
