import 'package:flutter/material.dart';

import '../../data/models/bahan_pakan.dart';
import '../../data/sources/bahan_pakan_repository.dart';

class MasterPakanScreen extends StatefulWidget {
  const MasterPakanScreen({super.key});

  @override
  State<MasterPakanScreen> createState() => _MasterPakanScreenState();
}

class _MasterPakanScreenState extends State<MasterPakanScreen> {
  final BahanPakanRepository _repository = BahanPakanRepository();

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _repository.initialize();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat master pakan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _bukaFormBahan({BahanPakan? bahan}) async {
    final hasil = await showModalBottomSheet<BahanPakan>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FormBahanPakanSheet(
        initialData: bahan,
        nextId: bahan?.id ?? _repository.nextId(),
      ),
    );

    if (hasil == null) return;

    if (bahan == null) {
      await _repository.addBahan(hasil);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bahan pakan baru berhasil disimpan.')),
      );
    } else {
      await _repository.updateBahan(bahan.id, hasil);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perubahan bahan pakan berhasil disimpan.')),
      );
    }

    setState(() {});
  }

  Future<void> _hapusBahan(BahanPakan bahan) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus bahan pakan'),
        content: Text('Hapus "${bahan.nama}" dari master pakan lokal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    await _repository.removeBahan(bahan.id);
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bahan pakan berhasil dihapus.')),
    );
  }

  Future<void> _ubahStatusAktif(BahanPakan bahan, bool isActive) async {
    await _repository.updateBahan(
      bahan.id,
      bahan.copyWith(isActive: isActive),
    );

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _resetDataAwal() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset master pakan'),
        content: const Text(
          'Data master pakan lokal akan dikembalikan ke bawaan aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    await _repository.resetKeDataAwal();
    if (!mounted) return;

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Master pakan dikembalikan ke data awal.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semuaData = _repository.semuaData;
    final totalAktif = semuaData.where((item) => item.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Bahan Pakan'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Reset data awal',
            onPressed: _isLoading ? null : _resetDataAwal,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : () => _bukaFormBahan(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Bahan'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_errorMessage!, textAlign: TextAlign.center),
                ),
              )
            : RefreshIndicator(
                onRefresh: _muatData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    _buildRingkasan(totalSemua: semuaData.length, totalAktif: totalAktif),
                    const SizedBox(height: 16),
                    if (semuaData.isEmpty)
                      _buildEmptyState()
                    else
                      ...semuaData.map(_buildBahanCard),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRingkasan({
    required int totalSemua,
    required int totalAktif,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.green.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data master pakan tersimpan di perangkat ini.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Anda bisa menambah, mengubah, menghapus, atau menonaktifkan bahan pakan. Perubahan akan dipakai oleh fitur perhitungan lainnya.',
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Data',
                  value: '$totalSemua bahan',
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Aktif Dipakai',
                  value: '$totalAktif bahan',
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 42, color: Colors.grey),
          SizedBox(height: 14),
          Text(
            'Belum ada bahan pakan tersimpan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Tekan tombol "Tambah Bahan" untuk membuat data master pakan lokal.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBahanCard(BahanPakan bahan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bahan.nama,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bahan.kategori,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: bahan.isActive,
                  onChanged: (value) => _ubahStatusAktif(bahan, value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(label: 'BK', value: '${bahan.bk.toStringAsFixed(2)}%'),
                _InfoChip(
                  label: 'Protein',
                  value: '${bahan.protein.toStringAsFixed(2)}%',
                ),
                _InfoChip(label: 'TDN', value: '${bahan.tdn.toStringAsFixed(2)}%'),
                _InfoChip(
                  label: 'Harga',
                  value: 'Rp ${bahan.hargaDefault.toStringAsFixed(0)}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _bukaFormBahan(bahan: bahan),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Ubah'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _hapusBahan(bahan),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormBahanPakanSheet extends StatefulWidget {
  final BahanPakan? initialData;
  final int nextId;

  const _FormBahanPakanSheet({
    required this.initialData,
    required this.nextId,
  });

  @override
  State<_FormBahanPakanSheet> createState() => _FormBahanPakanSheetState();
}

class _FormBahanPakanSheetState extends State<_FormBahanPakanSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _kategoriController;
  late final TextEditingController _bkController;
  late final TextEditingController _abuController;
  late final TextEditingController _lemakController;
  late final TextEditingController _seratController;
  late final TextEditingController _proteinController;
  late final TextEditingController _betnController;
  late final TextEditingController _tdnController;
  late final TextEditingController _meController;
  late final TextEditingController _hargaController;

  late bool _isActive;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _namaController = TextEditingController(text: data?.nama ?? '');
    _kategoriController = TextEditingController(text: data?.kategori ?? '');
    _bkController = TextEditingController(text: _formatNumber(data?.bk));
    _abuController = TextEditingController(text: _formatNumber(data?.abu));
    _lemakController = TextEditingController(text: _formatNumber(data?.lemak));
    _seratController = TextEditingController(text: _formatNumber(data?.serat));
    _proteinController = TextEditingController(text: _formatNumber(data?.protein));
    _betnController = TextEditingController(text: _formatNumber(data?.betn));
    _tdnController = TextEditingController(text: _formatNumber(data?.tdn));
    _meController = TextEditingController(text: _formatNumber(data?.me));
    _hargaController = TextEditingController(
      text: data == null ? '' : data.hargaDefault.toStringAsFixed(0),
    );
    _isActive = data?.isActive ?? true;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kategoriController.dispose();
    _bkController.dispose();
    _abuController.dispose();
    _lemakController.dispose();
    _seratController.dispose();
    _proteinController.dispose();
    _betnController.dispose();
    _tdnController.dispose();
    _meController.dispose();
    _hargaController.dispose();
    super.dispose();
  }

  String _formatNumber(double? value) {
    if (value == null) return '';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2);
  }

  double _parseNumber(String value) {
    return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      BahanPakan(
        id: widget.initialData?.id ?? widget.nextId,
        nama: _namaController.text.trim(),
        kategori: _kategoriController.text.trim(),
        bk: _parseNumber(_bkController.text),
        abu: _parseNumber(_abuController.text),
        lemak: _parseNumber(_lemakController.text),
        serat: _parseNumber(_seratController.text),
        protein: _parseNumber(_proteinController.text),
        betn: _parseNumber(_betnController.text),
        tdn: _parseNumber(_tdnController.text),
        me: _parseNumber(_meController.text),
        hargaDefault: _parseNumber(_hargaController.text),
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (context, scrollController) {
          return Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit ? 'Ubah Bahan Pakan' : 'Tambah Bahan Pakan',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lengkapi data nutrisi dan harga. Data ini akan disimpan lokal di perangkat.',
                      style: TextStyle(height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _namaController,
                      label: 'Nama bahan pakan',
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _kategoriController,
                      label: 'Kategori',
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _bkController,
                            label: 'BK (%)',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberField(
                            controller: _abuController,
                            label: 'Abu (%)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _lemakController,
                            label: 'Lemak (%)',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberField(
                            controller: _seratController,
                            label: 'Serat (%)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _proteinController,
                            label: 'Protein (%)',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberField(
                            controller: _betnController,
                            label: 'BETN (%)',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildNumberField(
                            controller: _tdnController,
                            label: 'TDN (%)',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildNumberField(
                            controller: _meController,
                            label: 'ME',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildNumberField(
                      controller: _hargaController,
                      label: 'Harga default per kg',
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Aktif dipakai di perhitungan'),
                      subtitle: const Text(
                        'Jika dimatikan, bahan tidak muncul di pilihan kalkulasi.',
                      ),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _simpan,
                        child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Bahan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Wajib diisi';
    }
    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: _requiredValidator,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade700),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }
}
