import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_header.dart';
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
      backgroundColor: AppColors.backgroundCream,
      appBar: AppHeader(
        title: 'Master Bahan Pakan',
        heading: 'Database Pakan',
        subtitle: 'Kelola basis data bahan pakan yang tersedia secara lokal.',
        actions: [
          IconButton(
            tooltip: 'Reset Data',
            onPressed: _isLoading ? null : _resetDataAwal,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : () => _bukaFormBahan(),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Bahan'),
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
              : RefreshIndicator(
                  onRefresh: _muatData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    children: [
                      const SizedBox(height: 24),
                      _buildRingkasan(totalSemua: semuaData.length, totalAktif: totalAktif),
                      const SizedBox(height: 16),
                      if (semuaData.isEmpty)
                        _buildEmptyState()
                      else
                        ...semuaData.map(_buildBahanCard),
                    ],
                  ),
                ),
    );
  }


  Widget _buildRingkasan({
    required int totalSemua,
    required int totalAktif,
  }) {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.inventory_2_outlined, color: AppColors.primaryGreen, size: 20),
                const SizedBox(height: 8),
                Text('Total Pakan', style: Theme.of(context).textTheme.bodySmall),
                Text('$totalSemua', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.accentGreen, size: 20),
                const SizedBox(height: 8),
                Text('Bahan Aktif', style: Theme.of(context).textTheme.bodySmall),
                Text('$totalAktif', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return AppCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppColors.primaryGreen.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text('Database Kosong', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Belum ada data bahan pakan yang tersimpan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBahanCard(BahanPakan bahan) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bahan.nama,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      bahan.kategori.toUpperCase(),
                      style: const TextStyle(fontSize: 10, color: AppColors.textGrey, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              Switch(
                value: bahan.isActive,
                activeThumbColor: AppColors.primaryGreen,
                onChanged: (value) => _ubahStatusAktif(bahan, value),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('BK', '${bahan.bk.toStringAsFixed(1)}%'),
              _buildMetric('PK', '${bahan.protein.toStringAsFixed(1)}%'),
              _buildMetric('TDN', '${bahan.tdn.toStringAsFixed(1)}%'),
              _buildMetric('Harga', 'Rp${bahan.hargaDefault.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _bukaFormBahan(bahan: bahan),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => _hapusBahan(bahan),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.errorRed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
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
  late final TextEditingController _bkController;
  late final TextEditingController _proteinController;
  late final TextEditingController _tdnController;
  late final TextEditingController _hargaController;

  late bool _isActive;
  String? _selectedKategori;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    _namaController = TextEditingController(text: data?.nama ?? '');
    _bkController = TextEditingController(text: _formatNumber(data?.bk));
    _proteinController = TextEditingController(text: _formatNumber(data?.protein));
    _tdnController = TextEditingController(text: _formatNumber(data?.tdn));
    _hargaController = TextEditingController(
      text: data == null ? '' : data.hargaDefault.toStringAsFixed(0),
    );
    _selectedKategori = data?.kategori;
    _isActive = data?.isActive ?? true;
  }

  @override
  void dispose() {
    _namaController.dispose();
    _bkController.dispose();
    _proteinController.dispose();
    _tdnController.dispose();
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
        kategori: _selectedKategori!,
        bk: _parseNumber(_bkController.text),
        abu: widget.initialData?.abu ?? 0,
        lemak: widget.initialData?.lemak ?? 0,
        serat: widget.initialData?.serat ?? 0,
        protein: _parseNumber(_proteinController.text),
        betn: widget.initialData?.betn ?? 0,
        tdn: _parseNumber(_tdnController.text),
        me: widget.initialData?.me ?? 0,
        hargaDefault: _parseNumber(_hargaController.text),
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isEdit ? 'Ubah Bahan' : 'Tambah Bahan Baru',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              AppTextField(
                controller: _namaController,
                label: 'Nama Bahan Pakan',
                hintText: 'Contoh: Rumput Gajah',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedKategori,
                decoration: const InputDecoration(labelText: 'Kategori'),
                items: const [
                  DropdownMenuItem(value: 'hijauan', child: Text('Hijauan')),
                  DropdownMenuItem(value: 'konsentrat', child: Text('Konsentrat')),
                  DropdownMenuItem(value: 'limbah', child: Text('Limbah')),
                  DropdownMenuItem(value: 'energi', child: Text('Energi')),
                  DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
                ],
                onChanged: (v) => setState(() => _selectedKategori = v),
                validator: (v) => v == null ? 'Wajib' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _bkController,
                      label: 'BK (%)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _proteinController,
                      label: 'PK (%)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _tdnController,
                      label: 'TDN (%)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _hargaController,
                      label: 'Harga /kg',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bahan Aktif'),
                subtitle: const Text('Muncul di pilihan kalkulasi', style: TextStyle(fontSize: 12)),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _simpan,
                  child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Bahan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Removed legacy _StatCard and other helpers
