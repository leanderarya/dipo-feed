import 'package:flutter/material.dart';

import '../../data/models/bahan_pakan.dart';
import '../../data/models/campuran_pakan_item.dart';
import '../../data/models/hasil_pakan_terpilih.dart';
import '../../data/sources/bahan_pakan_repository.dart';
import 'logic/perhitungan_nutrisi.dart';

class CekKandunganNutrisiScreen extends StatefulWidget {
  final bool modePilihUntukEvaluasi;

  const CekKandunganNutrisiScreen({
    super.key,
    this.modePilihUntukEvaluasi = false,
  });

  @override
  State<CekKandunganNutrisiScreen> createState() =>
      _CekKandunganNutrisiScreenState();
}

class _CekKandunganNutrisiScreenState extends State<CekKandunganNutrisiScreen> {
  final BahanPakanRepository _repository = BahanPakanRepository();

  List<BahanPakan> _semuaBahan = [];
  final List<CampuranPakanItem> _campuran = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _muatBahanPakan();
  }

  Future<void> _muatBahanPakan() async {
    try {
      await _repository.initialize();

      setState(() {
        _semuaBahan = _repository.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat bahan pakan: $e';
        _isLoading = false;
      });
    }
  }

  void _bukaManajemenMaster() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _MasterPakanSheet(
        onUpdate: () {
          setState(() {
            _semuaBahan = _repository.data;
          });
        },
      ),
    );
  }

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
    final sudahDipakaiOlehItemLain = _campuran.asMap().entries.any((entry) {
      return entry.key != index && entry.value.bahan.id == bahanBaru.id;
    });

    if (sudahDipakaiOlehItemLain) {
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

  void _ubahHargaPerKg(int index, String value) {
    final harga = double.tryParse(value.replaceAll(',', '.')) ?? 0;

    setState(() {
      _campuran[index].hargaPerKg = harga < 0 ? 0 : harga;
    });
  }

  void _gunakanUntukEvaluasi(HasilPerhitunganNutrisi hasil) {
    if (hasil.totalBerat <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total campuran pakan harus lebih dari 0 kg.'),
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
    final hasil = PerhitunganNutrisi.hitungSemua(_campuran);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cek Kandungan Nutrisi'),
        centerTitle: true,
      ),
      floatingActionButton: _buildFabGroup(),
      body: SafeArea(child: _buildBody(hasil)),
      bottomNavigationBar:
          widget.modePilihUntukEvaluasi &&
              _campuran.isNotEmpty &&
              hasil.totalBerat > 0
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: FilledButton.icon(
                onPressed: () => _gunakanUntukEvaluasi(hasil),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Gunakan untuk Evaluasi'),
              ),
            )
          : null,
    );
  }

  Widget _buildFabGroup() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'fab_master',
          onPressed: _isLoading ? null : _bukaManajemenMaster,
          backgroundColor: Colors.orange.shade700,
          child: const Icon(Icons.inventory_2_outlined, color: Colors.white),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'fab_add',
          onPressed: _isLoading ? null : _tambahBahan,
          icon: const Icon(Icons.add),
          label: const Text('Tambah Bahan'),
        ),
      ],
    );
  }

  Widget _buildBody(HasilPerhitunganNutrisi hasil) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_errorMessage!, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildRingkasanSingkat(hasil),
        const SizedBox(height: 16),
        if (_campuran.isEmpty)
          _buildEmptyState()
        else ...[
          ...List.generate(
            _campuran.length,
            (index) => _buildKartuBahan(index, _campuran[index]),
          ),
          const SizedBox(height: 16),
          _buildKartuHasil(hasil),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Formulasi Campuran Pakan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 6),
          Text(
            'Tambahkan bahan pakan, isi jumlah dan harga, lalu sistem akan menghitung kandungan nutrisi campuran.',
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasanSingkat(HasilPerhitunganNutrisi hasil) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _campuran.isEmpty
            ? const Text(
                'Belum ada bahan pakan yang dipilih.',
                textAlign: TextAlign.center,
              )
            : Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniStat(
                          'Jumlah Bahan',
                          '${_campuran.length}',
                        ),
                      ),
                      Expanded(
                        child: _buildMiniStat(
                          'Total Berat',
                          '${hasil.totalBerat.toStringAsFixed(2)} kg',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniStat(
                          'Protein',
                          '${hasil.protein.toStringAsFixed(2)}%',
                        ),
                      ),
                      Expanded(
                        child: _buildMiniStat(
                          'TDN',
                          '${hasil.tdn.toStringAsFixed(2)}%',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        children: [
          Icon(Icons.feed_outlined, size: 40, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Belum ada bahan yang ditambahkan.',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            'Tekan tombol "Tambah Bahan" untuk mulai membuat campuran pakan.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildKartuBahan(int index, CampuranPakanItem item) {
    final totalBerat = PerhitunganNutrisi.hitungTotalBerat(_campuran);
    final persentase = PerhitunganNutrisi.hitungPersentaseBahan(
      item.jumlahKg,
      totalBerat,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bahan ${index + 1}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus bahan',
                  onPressed: () => _hapusBahan(index),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<BahanPakan>(
              initialValue: item.bahan,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Pilih Bahan Pakan',
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
                  _ubahBahan(index, value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('jumlah_$index'),
              initialValue: item.jumlahKg == 0
                  ? ''
                  : item.jumlahKg.toStringAsFixed(2),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) => _ubahJumlahKg(index, value),
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                suffixText: 'kg',
                border: OutlineInputBorder(),
                hintText: 'Contoh: 10',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('harga_$index'),
              initialValue: item.hargaPerKg == 0
                  ? ''
                  : item.hargaPerKg.toStringAsFixed(0),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) => _ubahHargaPerKg(index, value),
              decoration: const InputDecoration(
                labelText: 'Harga per kg',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
                hintText: 'Contoh: 3500',
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoChip('Kategori', item.bahan.kategori),
                _buildInfoChip(
                  'Komposisi',
                  '${persentase.toStringAsFixed(2)}%',
                ),
                _buildInfoChip(
                  'Protein',
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildKartuHasil(HasilPerhitunganNutrisi hasil) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hasil Perhitungan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dari hasil perhitungan di atas, dapat diketahui bahwa pakan yang Anda berikan kepada sapi perah mengandung:',
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
            _buildItemHasil('Bahan Kering', '${hasil.bk.toStringAsFixed(2)}%'),
            _buildItemHasil('Abu', '${hasil.abu.toStringAsFixed(2)}%'),
            _buildItemHasil('Lemak', '${hasil.lemak.toStringAsFixed(2)}%'),
            _buildItemHasil('Serat', '${hasil.serat.toStringAsFixed(2)}%'),
            _buildItemHasil('Protein', '${hasil.protein.toStringAsFixed(2)}%'),
            _buildItemHasil('TDN', '${hasil.tdn.toStringAsFixed(2)}%'),
            _buildItemHasil(
              'Dengan harga per kg',
              'Rp ${hasil.hargaRataRata.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildItemHasil(
              'Total Berat Campuran',
              '${hasil.totalBerat.toStringAsFixed(2)} kg',
            ),
            _buildItemHasil(
              'Total Biaya',
              'Rp ${hasil.totalBiaya.toStringAsFixed(0)}',
            ),
          ],
        ),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MasterPakanSheet extends StatefulWidget {
  final VoidCallback onUpdate;

  const _MasterPakanSheet({required this.onUpdate});

  @override
  State<_MasterPakanSheet> createState() => _MasterPakanSheetState();
}

class _MasterPakanSheetState extends State<_MasterPakanSheet> {
  final BahanPakanRepository _repository = BahanPakanRepository();

  @override
  Widget build(BuildContext context) {
    final data = _repository.data;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          Expanded(
            child: data.isEmpty
                ? const Center(child: Text('Belum ada data master pakan.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: data.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final bahan = data[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          bahan.nama,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${bahan.kategori} • BK: ${bahan.bk}% • PK: ${bahan.protein}%',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // Placeholder for Edit
                        },
                      );
                    },
                  ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.inventory_2, color: Colors.orange),
          const SizedBox(width: 12),
          const Text(
            'Manajemen Master Pakan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fitur tambah pakan baru akan segera hadir.'),
              ),
            );
          },
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Tambah Bahan Pakan ke Library'),
        ),
      ),
    );
  }
}
