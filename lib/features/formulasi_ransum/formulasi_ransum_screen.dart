import 'package:flutter/material.dart';

import '../../data/models/bahan_pakan.dart';
import '../../data/models/campuran_pakan_item.dart';
import '../../data/models/hasil_kecukupan_pakan.dart';
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
      appBar: AppBar(
        title: const Text('Buat Formulasi Ransum'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoadingBahan ? null : _tambahBahan,
        backgroundColor: const Color(0xFF457042),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Bahan'),
      ),
      body: SafeArea(
        child: _isLoadingBahan
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderInfo(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('1. Profil Sapi'),
                    _buildCardDataSapi(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('2. Pilih Bahan Pakan yang Tersedia'),
                    const SizedBox(height: 8),
                    if (_bahanTerpilih.isEmpty)
                      _buildEmptyBahanState()
                    else
                      ...List.generate(
                        _bahanTerpilih.length,
                        (index) => _buildKartuBahan(index, _bahanTerpilih[index]),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF457042),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _hitungFormulasi,
                        child: const Text(
                          'Hitung Formulasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_tahapLaktasiTerdeteksi != null)
                      _buildTahapLaktasiInfo(),
                    if (_tahapLaktasiTerdeteksi != null)
                      const SizedBox(height: 16),
                    if (_hasilFormulasi != null) ...[
                      _buildKartuImbanganPakan(),
                      const SizedBox(height: 16),
                      _buildKartuHasilFormulasi(),
                      const SizedBox(height: 16),
                      _buildKartuEvaluasiNutrisi(),
                    ],
                  ],
                ),
              ),
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
            'Masukkan data sapi, lalu pilih bahan pakan yang tersedia. Sistem akan menghitung rekomendasi jumlah pakan per ekor per hari.',
          ),
        ],
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

  Widget _buildLabelWithInfo(String label, String message) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabelWithInfo(
                              'Produksi susu',
                              'Diisi jumlah produksi susu rata-rata per hari dalam liter per ekor.',
                            ),
                            const SizedBox(height: 8),
                            _buildNumberField(
                              controller: _produksiSusuController,
                              label: 'Produksi susu',
                              suffix: 'liter/ekor/hari',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabelWithInfo(
                              'Lemak susu',
                              'Saat ini belum digunakan dalam perhitungan, hanya sebagai data profil sapi.',
                            ),
                            const SizedBox(height: 8),
                            _buildNumberField(
                              controller: _lemakSusuController,
                              label: 'Lemak susu',
                              suffix: '%',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabelWithInfo(
                              'Periode Laktasi',
                              'Jumlah berapa kali sapi sudah beranak. Contoh: jika sapi sudah melahirkan 2 kali, maka isi 2.',
                            ),
                            const SizedBox(height: 8),
                            _buildNumberField(
                              controller: _paritasController,
                              label: 'Periode Laktasi',
                              suffix: 'ke',
                              isInteger: true,
                            ),
                          ],
                        ),
                      ),
                    ],
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
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status kebuntingan',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
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
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Wajib diisi';

        if (isInteger) {
          final parsed = int.tryParse(v);
          if (parsed == null) return 'Masukkan angka bulat yang valid';
          if (parsed < 0) return 'Tidak boleh negatif';
        } else {
          final parsed = double.tryParse(v.replaceAll(',', '.'));
          if (parsed == null) return 'Masukkan angka yang valid';
          if (parsed < 0) return 'Tidak boleh negatif';
        }

        return null;
      },
    );
  }

  Widget _buildEmptyBahanState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Text(
          'Belum ada bahan pakan yang dipilih.',
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DropdownButtonFormField<BahanPakan>(
                initialValue: item.bahan,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Pilih Bahan',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
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
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTahapLaktasiInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildKartuImbanganPakan() {
    final hasil = _hasilFormulasi!;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Imbangan Pakan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildItemHasil(
              'Hijauan',
              '${hasil.persentaseHijauan.toStringAsFixed(2)} %',
            ),
            _buildItemHasil(
              'Konsentrat',
              '${hasil.persentaseKonsentrat.toStringAsFixed(2)} %',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKartuHasilFormulasi() {
    final hasil = _hasilFormulasi!;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hasil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Berdasarkan bahan pakan yang dipilih dan sesuai dengan kondisi fisiologis sapi perah Anda, maka pakan yang sebaiknya Anda berikan adalah:',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
            ...hasil.rekomendasiPakan.map(
              (item) => _buildItemHasil(
                item.namaBahan,
                '${item.jumlahKg.toStringAsFixed(2)} kg/ekor/hari',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKartuEvaluasiNutrisi() {
    final ev = _hasilFormulasi!.evaluasi;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Evaluasi Nutrisi Formulasi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  detail.status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildBarisEvaluasi(
            'Pemberian (Formulasi)',
            formatNilai(detail.pemberian),
          ),
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
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: valueColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemHasil(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}