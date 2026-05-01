import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_header.dart';
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
  });

  @override
  State<RekomendasiPakanScreen> createState() => _RekomendasiPakanScreenState();
}

class _RekomendasiPakanScreenState extends State<RekomendasiPakanScreen> {
  final _formKey = GlobalKey<FormState>();
  final BahanPakanRepository _repository = BahanPakanRepository();

  final TextEditingController _beratBadanController = TextEditingController();
  final TextEditingController _produksiSusuController = TextEditingController();
  final TextEditingController _lemakSusuController = TextEditingController();

  FisiologiSapi _fisiologi = FisiologiSapi.dara;
  bool _isLoading = true;
  String? _errorMessage;

  List<BahanPakan> _semuaBahan = [];
  List<BahanPakan?> _hijauanTerpilih = [];
  List<BahanPakan?> _konsentratTerpilih = [];

  KebutuhanNutrienSapi? _kebutuhanNutrien;
  HasilRekomendasiPakan? _hasilRekomendasi;

  @override
  void initState() {
    super.initState();
    _kebutuhanNutrien = widget.kebutuhanAwal;
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
    });
  }

  List<BahanPakan> get _opsiHijauan => _semuaBahan.where(_isHijauan).toList();
  List<BahanPakan> get _opsiKonsentrat =>
      _semuaBahan.where(_isKonsentrat).toList();

  void _ubahFisiologi(FisiologiSapi? value) {
    if (value == null) return;
    setState(() {
      _fisiologi = value;
      _hasilRekomendasi = null;
      if (_fisiologi != FisiologiSapi.laktasi) {
        _produksiSusuController.clear();
        _lemakSusuController.clear();
      }
    });
    _perbaruiPreviewKebutuhan();
  }

  void _gunakanDataCekKecukupan() {
    if (widget.kebutuhanAwal == null) {
      _showSnackBar('Data Cek Kecukupan belum tersedia.');
      return;
    }

    setState(() {
      _beratBadanController.clear();
      _produksiSusuController.clear();
      _lemakSusuController.clear();
      _kebutuhanNutrien = widget.kebutuhanAwal;
      _hasilRekomendasi = null;
    });
  }

  void _tambahHijauan() {
    setState(() {
      _hijauanTerpilih = [..._hijauanTerpilih, null];
      _hasilRekomendasi = null;
    });
  }

  void _tambahKonsentrat() {
    setState(() {
      _konsentratTerpilih = [..._konsentratTerpilih, null];
      _hasilRekomendasi = null;
    });
  }

  void _hapusHijauan(int index) {
    setState(() {
      _hijauanTerpilih = List.of(_hijauanTerpilih)..removeAt(index);
      _hasilRekomendasi = null;
    });
  }

  void _hapusKonsentrat(int index) {
    setState(() {
      _konsentratTerpilih = List.of(_konsentratTerpilih)..removeAt(index);
      _hasilRekomendasi = null;
    });
  }

  void _ubahHijauan(int index, BahanPakan? value) {
    if (value == null) return;
    final duplikatKelompok = _hijauanTerpilih.asMap().entries.any((entry) {
      return entry.key != index && entry.value?.id == value.id;
    });
    final duplikatLintasKelompok =
        _konsentratTerpilih.any((item) => item?.id == value.id);

    if (duplikatKelompok || duplikatLintasKelompok) {
      _showSnackBar('Bahan pakan tersebut sudah dipilih.');
      return;
    }

    setState(() {
      _hijauanTerpilih[index] = value;
      _hasilRekomendasi = null;
    });
  }

  void _ubahKonsentrat(int index, BahanPakan? value) {
    if (value == null) return;
    final duplikatKelompok = _konsentratTerpilih.asMap().entries.any((entry) {
      return entry.key != index && entry.value?.id == value.id;
    });
    final duplikatLintasKelompok =
        _hijauanTerpilih.any((item) => item?.id == value.id);

    if (duplikatKelompok || duplikatLintasKelompok) {
      _showSnackBar('Bahan pakan tersebut sudah dipilih.');
      return;
    }

    setState(() {
      _konsentratTerpilih[index] = value;
      _hasilRekomendasi = null;
    });
  }

  void _hitungRekomendasi() {
    if (!_formKey.currentState!.validate()) return;

    final kebutuhan = _hitungKebutuhanDariForm();
    if (kebutuhan == null) {
      _showSnackBar('Lengkapi kebutuhan nutrien sapi terlebih dahulu.');
      return;
    }

    final hijauan = _hijauanTerpilih.whereType<BahanPakan>().toList();
    final konsentrat = _konsentratTerpilih.whereType<BahanPakan>().toList();

    if (hijauan.isEmpty) {
      _showSnackBar('Tambahkan minimal satu hijauan.');
      return;
    }

    if (konsentrat.isEmpty) {
      _showSnackBar('Tambahkan minimal satu konsentrat.');
      return;
    }

    if (_hijauanTerpilih.any((item) => item == null) ||
        _konsentratTerpilih.any((item) => item == null)) {
      _showSnackBar('Lengkapi semua pilihan bahan pakan terlebih dahulu.');
      return;
    }

    final semuaBahan = [...hijauan, ...konsentrat];
    final adaBkKosong = semuaBahan.any((item) => item.bk <= 0);
    if (adaBkKosong) {
      _showSnackBar('Semua bahan pakan harus memiliki nilai BK lebih dari 0.');
      return;
    }

    final hasil = PerhitunganRekomendasiPakan.hitung(
      kebutuhan: kebutuhan,
      bahanHijauan: hijauan,
      bahanKonsentrat: konsentrat,
    );

    setState(() {
      _kebutuhanNutrien = kebutuhan;
      _hasilRekomendasi = hasil;
    });

    if (!hasil.isLkAman) {
      _showSnackBar('LK melebihi batas 5% BK.');
    }
  }

  KebutuhanNutrienSapi? _hitungKebutuhanDariForm() {
    if (widget.kebutuhanAwal != null &&
        _beratBadanController.text.trim().isEmpty &&
        _produksiSusuController.text.trim().isEmpty &&
        _lemakSusuController.text.trim().isEmpty) {
      return widget.kebutuhanAwal;
    }

    final beratBadan = _parseDouble(_beratBadanController.text);
    final produksiSusu = _parseDouble(_produksiSusuController.text);
    final lemakSusu = _parseDouble(_lemakSusuController.text);

    if (beratBadan <= 0) return null;
    if (_fisiologi == FisiologiSapi.laktasi &&
        (produksiSusu <= 0 || lemakSusu <= 0)) {
      return null;
    }

    return PerhitunganKebutuhanNutrien.hitungKebutuhan(
      fisiologi: _fisiologi,
      beratBadan: beratBadan,
      produksiSusuLiter:
          _fisiologi == FisiologiSapi.laktasi ? produksiSusu : null,
      lemakSusuPersen:
          _fisiologi == FisiologiSapi.laktasi ? lemakSusu : null,
    );
  }

  double _parseDouble(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  String _format(double value) => value.toStringAsFixed(2);

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

  bool _isHijauan(BahanPakan bahan) {
    final kategori = bahan.kategori.toLowerCase();
    return kategori.contains('hijauan') ||
        kategori.contains('rumput') ||
        kategori.contains('forage');
  }

  bool _isKonsentrat(BahanPakan bahan) {
    final kategori = bahan.kategori.toLowerCase();
    return kategori.contains('konsentrat') ||
        kategori.contains('energi') ||
        kategori.contains('protein') ||
        kategori.contains('pellet') ||
        kategori.contains('pollard') ||
        kategori.contains('dedak') ||
        kategori.contains('singkong');
  }

  String? _validasiBeratBadan(String? value) {
    if (value == null || value.trim().isEmpty) return 'BB wajib diisi';
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return 'Angka tidak valid';
    if (parsed <= 0) return 'BB harus lebih dari 0';
    return null;
  }

  String? _validasiProduksiSusu(String? value) {
    if (_fisiologi != FisiologiSapi.laktasi) return null;
    if (value == null || value.trim().isEmpty) return 'Produksi susu wajib diisi';
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return 'Angka tidak valid';
    if (parsed <= 0) return 'Produksi susu harus lebih dari 0';
    return null;
  }

  String? _validasiLemakSusu(String? value) {
    if (_fisiologi != FisiologiSapi.laktasi) return null;
    if (value == null || value.trim().isEmpty) return 'Lemak susu wajib diisi';
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed == null) return 'Angka tidak valid';
    if (parsed <= 0) return 'Lemak susu harus lebih dari 0';
    return null;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  double _hitungTotalAsFed(List<RekomendasiPakanItem> items) {
    return items.fold(0.0, (sum, item) => sum + item.asFedKg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: const AppHeader(
        title: 'Rekomendasi Pakan',
        heading: 'Rekomendasi Pakan',
        subtitle:
            'Pilih pakan yang dimiliki peternak. Sistem akan menghitung rekomendasi pemberian pakan berdasarkan kebutuhan nutrien sapi.',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_errorMessage!, textAlign: TextAlign.center),
                  ),
                )
              : SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfilCard(),
                        if (_kebutuhanNutrien != null) ...[
                          const SizedBox(height: 16),
                          _buildTargetBkPakanCard(_kebutuhanNutrien!),
                        ],
                        const SizedBox(height: 16),
                        _buildFeedSelectionCard(
                          title: 'Hijauan yang Dimiliki',
                          subtitle:
                              'Pilih bahan hijauan yang tersedia. Jumlah kg akan dihitung otomatis.',
                          icon: Icons.grass_rounded,
                          accentColor: const Color(0xFFB9E7C9),
                          avatarColor: const Color(0xFFDFF5E7),
                          items: _hijauanTerpilih,
                          opsi: _opsiHijauan,
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
                          opsi: _opsiKonsentrat,
                          onAdd: _tambahKonsentrat,
                          onRemove: _hapusKonsentrat,
                          onChanged: _ubahKonsentrat,
                          buttonLabel: 'Tambah Konsentrat',
                          emptyTitle: 'Belum ada konsentrat yang dipilih.',
                          emptyIcon: Icons.food_bank_outlined,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _hitungRekomendasi,
                            icon: const Icon(Icons.calculate_outlined),
                            label: const Text('Hitung Rekomendasi'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        if (_hasilRekomendasi != null) ...[
                          const SizedBox(height: 16),
                          _buildRecommendationCard(
                            title: 'Rekomendasi Hijauan',
                            icon: Icons.eco_outlined,
                            tint: const Color(0xFFE6F6EB),
                            accent: AppColors.primaryGreen,
                            items: _hasilRekomendasi!.rekomendasiHijauan,
                          ),
                          const SizedBox(height: 16),
                          _buildRecommendationCard(
                            title: 'Rekomendasi Konsentrat',
                            icon: Icons.restaurant_menu_outlined,
                            tint: const Color(0xFFFFF1DE),
                            accent: const Color(0xFFC77700),
                            items: _hasilRekomendasi!.rekomendasiKonsentrat,
                          ),
                          const SizedBox(height: 16),
                          _buildTotalSummaryCard(_hasilRekomendasi!),
                          const SizedBox(height: 16),
                          _buildEvaluationCard(_hasilRekomendasi!),
                        ],
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
                child: Icon(icon, size: 18, color: AppColors.primaryGreen),
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
      title: 'Profil Sapi / Kebutuhan Nutrien',
      icon: Icons.pets_outlined,
      subtitle:
          'Isi profil sapi atau gunakan data dari Cek Kecukupan untuk menampilkan kebutuhan nutrien.',
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_kebutuhanNutrien != null)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  _buildNutrientMiniCard('BK', '${_format(_kebutuhanNutrien!.kebutuhanBkKg)} kg'),
                  _buildNutrientMiniCard('PK', '${_format(_kebutuhanNutrien!.kebutuhanProteinKg)} kg'),
                  _buildNutrientMiniCard('TDN', '${_format(_kebutuhanNutrien!.kebutuhanTdnKg)} kg'),
                  _buildNutrientMiniCard('Ca', '${_format(_kebutuhanNutrien!.kebutuhanCaGram)} gram'),
                  _buildNutrientMiniCard('P', '${_format(_kebutuhanNutrien!.kebutuhanPGram)} gram'),
                ],
              )
            else
              _buildEmptyState(
                icon: Icons.fact_check_outlined,
                title: 'Data kebutuhan nutrien belum tersedia.',
                subtitle: 'Isi profil sapi terlebih dahulu agar target nutrien dapat dihitung.',
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (widget.kebutuhanAwal != null)
                  OutlinedButton.icon(
                    onPressed: _gunakanDataCekKecukupan,
                    icon: const Icon(Icons.sync_alt_outlined),
                    label: const Text('Gunakan Data Cek Kecukupan'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => _showSnackBar('Isi profil sapi pada form di bawah.'),
                    icon: const Icon(Icons.edit_note_outlined),
                    label: const Text('Isi Profil Sapi'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFieldLabel('Fisiologi Sapi'),
            const SizedBox(height: 8),
            DropdownButtonFormField<FisiologiSapi>(
              initialValue: _fisiologi,
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
                hintText: 'Misal: 3.5',
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
                      'Diisi sesuai dengan pengetahuan peternak, misalnya 3–3,5%.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                        height: 1.4,
                      ),
                    ),
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
              textColor: AppColors.primaryGreen,
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
    required List<BahanPakan> opsi,
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
              subtitle: 'Tambahkan bahan untuk mulai menghitung rekomendasi otomatis.',
            )
          else
            ...List.generate(
              items.length,
              (index) => Padding(
                padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 12),
                child: _buildFeedSelectionItem(
                  index: index,
                  item: items[index],
                  opsi: opsi,
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
    required int index,
    required BahanPakan? item,
    required List<BahanPakan> opsi,
    required VoidCallback onRemove,
    required void Function(BahanPakan? value) onChanged,
    required Color avatarColor,
    required Color accentColor,
  }) {
    return Container(
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
                child: Text(
                  bahan.nama,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
          if (item != null) ...[
            const SizedBox(height: 12),
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

  Widget _buildRecommendationCard({
    required String title,
    required IconData icon,
    required Color tint,
    required Color accent,
    required List<RekomendasiPakanItem> items,
  }) {
    return _buildSectionCard(
      title: title,
      icon: icon,
      child: items.isEmpty
          ? _buildEmptyState(
              icon: icon,
              title: 'Belum ada rekomendasi yang bisa dihitung.',
              subtitle: 'Periksa kembali pilihan bahan pada kelompok ini.',
            )
          : Column(
              children: items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRecommendationItem(
                        item: item,
                        tint: tint,
                        accent: accent,
                      ),
                    ),
                  )
                  .toList(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.bahan.nama,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${_format(item.asFedKg)} kg/ekor/hari',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: accent,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'BK: ${_format(item.bkKg)} kg',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSummaryCard(HasilRekomendasiPakan hasil) {
    final total = hasil.totalGabungan;
    final totalAsFed = _hitungTotalAsFed(hasil.rekomendasiHijauan) +
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
        childAspectRatio: 1.55,
        children: [
          _buildNutrientMiniCard('Total As Fed', '${_format(totalAsFed)} kg/ekor/hari'),
          _buildNutrientMiniCard('Total BK', '${_format(total.bkKg)} kg'),
          _buildNutrientMiniCard('Total PK', '${_format(total.pkKg)} kg'),
          _buildNutrientMiniCard('Total TDN', '${_format(total.tdnKg)} kg'),
          _buildNutrientMiniCard('Total Ca', '${_format(total.caGram)} gram'),
          _buildNutrientMiniCard('Total P', '${_format(total.pGram)} gram'),
          _buildNutrientMiniCard('LK', '${_format(hasil.lkPersenDariBk)}% dari BK'),
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
              color: hasil.isLkAman
                  ? const Color(0xFFE6F6EB)
                  : const Color(0xFFFFE6DE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hasil.isLkAman
                      ? Icons.verified_outlined
                      : Icons.warning_amber_rounded,
                  color: hasil.isLkAman
                      ? AppColors.primaryGreen
                      : const Color(0xFFB8571B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasil.isLkAman
                        ? 'LK aman (${_format(hasil.lkPersenDariBk)}% dari BK)'
                        : 'LK melebihi batas 5% BK (${_format(hasil.lkPersenDariBk)}%).',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: hasil.isLkAman
                          ? AppColors.primaryGreen
                          : const Color(0xFFB8571B),
                    ),
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
    final selisih = hasilValue - target;
    final statusColor = status == 'Pas'
        ? AppColors.primaryGreen
        : status == 'Kurang'
            ? AppColors.errorRed
            : const Color(0xFFB8571B);

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
                  'Selisih ${selisih >= 0 ? '+' : ''}${_format(selisih)} $unit',
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientMiniCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
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
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
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
