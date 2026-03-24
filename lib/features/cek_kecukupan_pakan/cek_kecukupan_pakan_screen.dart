import 'package:flutter/material.dart';

import '../../data/models/hasil_kecukupan_pakan.dart';
import '../../data/models/hasil_pakan_terpilih.dart';
import '../../data/models/profil_sapi.dart';
import '../cek_kandungan_nutrisi/cek_kandungan_nutrisi_screen.dart';
import 'logic/perhitungan_kecukupan_pakan.dart';

class CekKecukupanPakanScreen extends StatefulWidget {
  const CekKecukupanPakanScreen({super.key});

  @override
  State<CekKecukupanPakanScreen> createState() =>
      _CekKecukupanPakanScreenState();
}

class _CekKecukupanPakanScreenState extends State<CekKecukupanPakanScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _beratBadanController = TextEditingController();
  final TextEditingController _produksiSusuController = TextEditingController();
  final TextEditingController _lemakSusuController = TextEditingController();
  final TextEditingController _paritasController = TextEditingController();
  final TextEditingController _bulanBuntingController = TextEditingController();

  TahapLaktasi _tahapLaktasi = TahapLaktasi.awalLaktasiMinggu0sampai4;
  StatusKebuntingan _statusKebuntingan = StatusKebuntingan.tidakBunting;

  KebutuhanNutrisiSapi? _hasilKebutuhan;
  HasilEvaluasiKecukupan? _hasilEvaluasi;
  HasilPakanTerpilih? _hasilPakanTerpilih;

  @override
  void dispose() {
    _beratBadanController.dispose();
    _produksiSusuController.dispose();
    _lemakSusuController.dispose();
    _paritasController.dispose();
    _bulanBuntingController.dispose();
    super.dispose();
  }

  // NAVIGASI KE FITUR 1
  Future<void> _ambilDariFitur1() async {
    final hasil = await Navigator.push<HasilPakanTerpilih>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CekKandunganNutrisiScreen(modePilihUntukEvaluasi: true),
      ),
    );

    if (hasil != null) {
      setState(() {
        _hasilPakanTerpilih = hasil;
      });
    }
  }

  // HITUNG EVALUASI
  void _hitungEvaluasi() {
    if (!_formKey.currentState!.validate()) return;

    if (_hasilPakanTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ambil dulu hasil pakan dari fitur 1.')),
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

    final kebutuhan = PerhitunganKecukupanPakan.hitungKebutuhan(profil);

    final evaluasi = PerhitunganKecukupanPakan.evaluasiDariHasilPakan(
      sapi: profil,
      hasilPakan: _hasilPakanTerpilih!,
    );

    setState(() {
      _hasilKebutuhan = kebutuhan;
      _hasilEvaluasi = evaluasi;
    });
  }

  double _parseDouble(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  int _parseInt(String value) {
    return int.tryParse(value) ?? 0;
  }

  // LABEL ENUM
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

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Kecukupan Pakan'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildFormInput(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Evaluasi Kecukupan Pakan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Isi data sapi dan ambil hasil pakan dari fitur 1 untuk mengetahui kecukupan nutrisi.',
          ),
        ],
      ),
    );
  }

  Widget _buildFormInput() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data Sapi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildNumberField(
                controller: _beratBadanController,
                label: 'Berat badan',
                suffix: 'kg',
              ),
              const SizedBox(height: 12),

              _buildNumberField(
                controller: _produksiSusuController,
                label: 'Produksi susu',
                suffix: 'liter/hari',
              ),
              const SizedBox(height: 12),

              _buildNumberField(
                controller: _lemakSusuController,
                label: 'Lemak susu',
                suffix: '%',
              ),
              const SizedBox(height: 12),

              _buildNumberField(
                controller: _paritasController,
                label: 'Paritas',
                suffix: 'kali',
                isInteger: true,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<TahapLaktasi>(
                initialValue: _tahapLaktasi,
                decoration: const InputDecoration(
                  labelText: 'Tahap laktasi',
                  border: OutlineInputBorder(),
                ),
                items: TahapLaktasi.values.map((tahap) {
                  return DropdownMenuItem(
                    value: tahap,
                    child: Text(_labelTahapLaktasi(tahap)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _tahapLaktasi = v!),
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

              const SizedBox(height: 20),

              const Text(
                'Pakan dari Fitur 1',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _hasilPakanTerpilih == null
                  ? const Text('Belum ada data pakan')
                  : Text(
                      'Total pakan: ${_hasilPakanTerpilih!.totalBeratKg.toStringAsFixed(2)} kg',
                    ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _ambilDariFitur1,
                icon: const Icon(Icons.call_received),
                label: const Text('Ambil dari Fitur 1'),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
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
      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
    );
  }

  Widget _buildKartuHasilKebutuhan() {
    if (_hasilKebutuhan == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildItemHasil('BK', _hasilKebutuhan!.kebutuhanBkKg),
            _buildItemHasil('Protein', _hasilKebutuhan!.kebutuhanProtein),
            _buildItemHasil('TDN', _hasilKebutuhan!.kebutuhanTdn),
            _buildItemHasil('ME', _hasilKebutuhan!.kebutuhanMe),
          ],
        ),
      ),
    );
  }

  Widget _buildKartuHasilEvaluasi() {
    if (_hasilEvaluasi == null) return const SizedBox();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hasil Evaluasi Kecukupan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _hasilEvaluasi!.kesimpulanUmum,
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
            _buildKartuEvaluasiItem('BK', _hasilEvaluasi!.bk, 'kg'),
            _buildKartuEvaluasiItem('PK', _hasilEvaluasi!.protein, 'kg'),
            _buildKartuEvaluasiItem('TDN', _hasilEvaluasi!.tdn, 'kg'),
            _buildKartuEvaluasiItem('ME', _hasilEvaluasi!.me, ''),
            const SizedBox(height: 8),
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
                  color: color.withValues(alpha: 0.12),
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

  DataRow _buildEvaluasiRow(
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

    return DataRow(
      cells: [
        DataCell(Text(komponen)),
        DataCell(Text(formatNilai(detail.pemberian))),
        DataCell(Text(formatNilai(detail.kebutuhan))),
        DataCell(Text(formatSelisih(detail.selisih))),
        DataCell(
          Text(
            detail.status,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildItemHasil(String label, double value) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(value.toStringAsFixed(2)),
      ],
    );
  }
}
