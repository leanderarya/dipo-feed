import 'package:flutter/material.dart';

import '../../data/models/bahan_pakan.dart';
import '../../data/models/campuran_pakan_item.dart';
import '../../data/models/hasil_kecukupan_pakan.dart';
import '../../data/models/profil_sapi.dart';
import '../../data/sources/bahan_pakan_local_source.dart';
import 'logic/hasil_formulasi.dart';
import 'logic/perhitungan_formulasi.dart';

class FormulasiRansumScreen extends StatefulWidget {
  const FormulasiRansumScreen({super.key});

  @override
  State<FormulasiRansumScreen> createState() => _FormulasiRansumScreenState();
}

class _FormulasiRansumScreenState extends State<FormulasiRansumScreen> {
  final _formKey = GlobalKey<FormState>();

  // Profil Sapi Controllers
  final TextEditingController _beratBadanController = TextEditingController();
  final TextEditingController _produksiSusuController = TextEditingController();
  final TextEditingController _lemakSusuController = TextEditingController();
  final TextEditingController _paritasController = TextEditingController();
  final TextEditingController _bulanBuntingController = TextEditingController();

  TahapLaktasi _tahapLaktasi = TahapLaktasi.awalLaktasiMinggu0sampai4;
  StatusKebuntingan _statusKebuntingan = StatusKebuntingan.tidakBunting;

  // Bahan Pakan State
  final BahanPakanLocalSource _localSource = BahanPakanLocalSource();
  List<BahanPakan> _semuaBahan = [];
  final List<CampuranPakanItem> _campuran = [];
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
    super.dispose();
  }

  Future<void> _muatBahanPakan() async {
    try {
      final data = await _localSource.ambilSemuaBahanPakan();
      setState(() {
        _semuaBahan = data;
        _isLoadingBahan = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat bahan pakan: $e')),
        );
      }
      setState(() {
        _isLoadingBahan = false;
      });
    }
  }

  // == Logika Tambah/Hapus Bahan (Mirip Fitur 1) ==
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
        const SnackBar(
          content: Text('Semua bahan pakan aktif sudah ditambahkan.'),
        ),
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
    final sudahDipakai = _campuran.asMap().entries.any((entry) {
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

  // == Helpers Parsing Angka ==
  double _parseDouble(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  int _parseInt(String value) {
    return int.tryParse(value) ?? 0;
  }

  // == Helper Enum Display ==
  String _labelTahapLaktasi(TahapLaktasi tahap) {
    switch (tahap) {
      case TahapLaktasi.keringKandang:
        return 'Kering kandang';
      case TahapLaktasi.awalLaktasiMinggu0sampai4:
        return 'Awal laktasi 0-4 minggu';
      case TahapLaktasi.awalLaktasiMinggu4sampai16:
        return 'Awal laktasi 4-16 minggu';
      case TahapLaktasi.tengahLaktasiMinggu16sampai30:
        return 'Tengah laktasi 16-30 minggu';
      case TahapLaktasi.akhirLaktasiMinggu30sampai44:
        return 'Akhir laktasi 30-44 minggu';
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

  // == Logika Perhitungan Utama ==
  void _hitungFormulasi() {
    if (!_formKey.currentState!.validate()) return;

    if (_campuran.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan tambah minimal 1 bahan pakan.')),
      );
      return;
    }
    
    // Pastikan tidak ada bahan pakan dengan berat 0
    final hasZeroWeight = _campuran.any((item) => item.jumlahKg <= 0);
    if (hasZeroWeight) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah (kg) setiap bahan harus lebih dari 0.')),
      );
      return;
    }

    final profil = ProfilSapi(
      beratBadan: _parseDouble(_beratBadanController.text),
      produksiSusu: _parseDouble(_produksiSusuController.text),
      persenLemakSusu: _parseDouble(_lemakSusuController.text),
      paritas: _parseInt(_paritasController.text),
      tahapLaktasi: _tahapLaktasi,
      statusKebuntingan: _statusKebuntingan,
      bulanBunting: _statusKebuntingan == StatusKebuntingan.bunting
          ? _parseInt(_bulanBuntingController.text)
          : 0,
    );

    final hasil = PerhitunganFormulasi.hitungFormulasi(
      sapi: profil,
      daftarBahan: _campuran,
    );

    setState(() {
      _hasilFormulasi = hasil;
    });

    // Scroll otomatis ke hasil bisa ditambahkan nanti jika diperlukan
  }

  // == UI Components ==
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Formulasi Ransum'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tambahBahan,
        backgroundColor: const Color(0xFF457042), // Matching the theme green
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Bahan'),
      ),
      body: SafeArea(
        child: _isLoadingBahan
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Added padding for FAB
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderInfo(),
                    const SizedBox(height: 20),
                    
                    // 1. Data Sapi Form
                    _buildSectionTitle('1. Profil Sapi'),
                    _buildCardDataSapi(),
                    const SizedBox(height: 24),
                    
                    // Hasil Formulasi (Moved here)
                    if (_hasilFormulasi != null) ...[
                      _buildSectionTitle('Hasil Kebutuhan & Simulasi'),
                      const SizedBox(height: 8),
                      _buildKartuHasilKesimpulan(),
                      const SizedBox(height: 16),
                      _buildKartuHasilNutrisi(),
                      const SizedBox(height: 24),
                    ],
                    
                    // 2. Data Bahan Pakan
                    _buildSectionTitle('2. Susun Ransum (Campur Pakan)'),
                    const SizedBox(height: 8),
                    if (_campuran.isEmpty)
                      _buildEmptyBahanState()
                    else
                      ...List.generate(
                        _campuran.length,
                        (index) => _buildKartuBahan(index, _campuran[index]),
                      ),
                    
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF457042),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: _hitungFormulasi,
                        child: const Text(
                          'Hitung Ransum', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Hasil moved up
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Simulator Formulasi Ransum',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Masukkan data profil sapi Anda, kemudian susun bahan pakan yang dikonsumsi (kg). Aplikasi akan mensimulasikan apakah campuran tersebut mencukupi kebutuhan sapi Anda.',
          ),
        ],
      ),
    );
  }

  Widget _buildCardDataSapi() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              // If width is enough, show 2 columns, otherwise 1
              final cardWidth = width > 400 ? (width - 12) / 2 : width;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: _buildNumberField(
                          controller: _beratBadanController,
                          label: 'Berat badan',
                          suffix: 'kg',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildNumberField(
                          controller: _produksiSusuController,
                          label: 'Produksi susu',
                          suffix: 'liter/ekor/hari',
                          helperText: 'Rata-rata produksi harian',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildNumberField(
                          controller: _lemakSusuController,
                          label: 'Lemak susu',
                          suffix: '%',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: _buildNumberField(
                          controller: _paritasController,
                          label: 'Periode Laktasi',
                          suffix: 'ke',
                          helperText: 'Jumlah masa laktasi',
                          isInteger: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TahapLaktasi>(
                    value: _tahapLaktasi,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Bulan Laktasi (mm-yyyy)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: TahapLaktasi.values.map((tahap) {
                      return DropdownMenuItem(
                        value: tahap,
                        child: Text(
                          _labelTahapLaktasi(tahap),
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _tahapLaktasi = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<StatusKebuntingan>(
                    value: _statusKebuntingan,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status kebuntingan',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: StatusKebuntingan.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          _labelStatusKebuntingan(status),
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _statusKebuntingan = v!),
                  ),
                  if (_statusKebuntingan == StatusKebuntingan.bunting) ...[
                    const SizedBox(height: 12),
                    _buildNumberField(
                      controller: _bulanBuntingController,
                      label: 'Bulan bunting',
                      suffix: 'bulan',
                      isInteger: true,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    String helperText = '',
    bool isInteger = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
      onChanged: (value) {
        if (!isInteger && value.contains('.')) {
          controller.text = value.replaceAll('.', ',');
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        }
      },
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        helperText: helperText, 
        border: const OutlineInputBorder(),
      ),
      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
    );
  }

  Widget _buildEmptyBahanState() {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
      ),
      child: const Center(
        child: Text(
          'Belum ada bahan pakan.',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildKartuBahan(int index, CampuranPakanItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<BahanPakan>(
                    value: item.bahan,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Bahan',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _semuaBahan.map((bahan) {
                      return DropdownMenuItem<BahanPakan>(
                        value: bahan,
                        child: Text(
                          bahan.nama, 
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) _ubahBahan(index, value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    tooltip: 'Hapus',
                    onPressed: () => _hapusBahan(index),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        key: ValueKey('jumlah_form_$index'),
                        initialValue: item.jumlahKg == 0 ? '' : item.jumlahKg.toStringAsFixed(2),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Banyak (As-fed)',
                          suffixText: 'kg',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        onChanged: (value) => _ubahJumlahKg(index, value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kadar BK',
                            style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${item.bahan.bk}%',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Kategori: ${item.bahan.kategori.toUpperCase()}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKartuHasilKesimpulan() {
    final hasil = _hasilFormulasi!;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timeline, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Imbangan Pakan (BK)',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCircleStat('Hijauan', hasil.persentaseHijauan, Colors.lightGreen),
                const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                _buildCircleStat('Konsentrat', hasil.persentaseKonsentrat, Colors.orange),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Kesimpulan:\n${hasil.evaluasi.kesimpulanUmum}',
              style: const TextStyle(fontWeight: FontWeight.w500, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleStat(String label, double percent, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                value: percent / 100,
                color: color,
                backgroundColor: Colors.grey.shade200,
                strokeWidth: 8,
              ),
            ),
            Text(
              '${percent.toStringAsFixed(0)}%',
              style: const TextStyle(fontWeight: FontWeight.bold),
            )
          ],
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildKartuHasilNutrisi() {
    final ev = _hasilFormulasi!.evaluasi;
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Pemenuhan Nutrisi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildKartuEvaluasiItem('Bahan Kering (BK)', ev.bk, 'kg'),
            _buildKartuEvaluasiItem('Protein Kasar (PK)', ev.protein, 'kg'),
            _buildKartuEvaluasiItem('TDN', ev.tdn, 'kg'),
            _buildKartuEvaluasiItem('Energi Metabolisme (ME)', ev.me, ''),
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  detail.status,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBarisEvaluasi('Pemberian (Ransum)', formatNilai(detail.pemberian)),
          _buildBarisEvaluasi('Kebutuhan Sapi', formatNilai(detail.kebutuhan)),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
