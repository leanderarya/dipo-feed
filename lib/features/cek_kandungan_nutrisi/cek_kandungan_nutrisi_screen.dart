import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/status_perhitungan.dart';
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
      setState(() {
        _errorMessage = 'Gagal memuat bahan pakan: $e';
        _isLoading = false;
      });
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
      });
    } catch (error) {
      setState(() {
        _hasilTerhitung = null;
        _statusPerhitungan = StatusPerhitungan.gagal;
        _pesanPerhitungan = error is FormatException
            ? error.message
            : 'Perhitungan nutrisi gagal dilakukan.';
      });
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

  void _gunakanUntukEvaluasi() {
    final hasil = _hasilTerhitung;
    if (_statusPerhitungan != StatusPerhitungan.berhasil || hasil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hitung campuran pakan sebelum digunakan untuk evaluasi.',
          ),
        ),
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

    return Scaffold(
      backgroundColor: AppColors.backgroundKrem,
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(
            title: 'Cek Kandungan Pakan',
            subtitle: 'Cek kandungan nutrisi pada pakan.',
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
          SliverToBoxAdapter(child: _buildBody(hasil, evaluasiStandar)),
        ],
      ),
      bottomNavigationBar: widget.modePilihUntukEvaluasi && _campuran.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _gunakanUntukEvaluasi,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentOrange,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Gunakan untuk Evaluasi'),
              ),
            )
          : null,
    );
  }

  Widget _buildBody(
    HasilPerhitunganNutrisi? hasil,
    HasilEvaluasiStandarNutrien? evaluasiStandar,
  ) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      child: Column(
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
            OutlinedButton.icon(
              onPressed: _tambahBahan,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Tambah Bahan Pakan'),
            ),
            if (evaluasiStandar != null && hasil != null) ...[
              const SizedBox(height: 16),
              EvaluasiStandarCard(
                evaluasi: evaluasiStandar,
                totalBeratKg: hasil.totalBerat,
                totalBiaya: hasil.totalBiaya,
              ),
            ],
          ],
          const SizedBox(height: 16),
          _buildPerhitunganStatus(),
        ],
      ),
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
                                '${item.bahan.kategori} • BK: ${IndonesianNumberFormatter.format(item.bahan.bk, decimals: 1)}%',
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
