import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/indonesian_number_formatter.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/app_sliver_header.dart';
import '../../data/csv/bahan_pakan_csv_codec.dart';
import '../../data/csv/hasil_import_bahan_pakan.dart';
import '../../data/models/bahan_pakan.dart';
import '../../data/sources/bahan_pakan_repository.dart';

typedef CsvPicker = Future<PlatformFile?> Function();
typedef CsvShare =
    Future<ShareResult> Function(
      Iterable<BahanPakan> data,
      Rect sharePositionOrigin,
    );

Future<PlatformFile?> _pickCsvDefault() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
    allowMultiple: false,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  return result.files.first;
}

Future<ShareResult> _shareCsvDefault(
  Iterable<BahanPakan> data,
  Rect sharePositionOrigin,
) {
  final csv = BahanPakanCsvCodec.serialize(data);
  return SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(utf8.encode(csv), mimeType: 'text/csv')],
      fileNameOverrides: ['database-pakan.csv'],
      sharePositionOrigin: sharePositionOrigin,
    ),
  );
}

class MasterPakanScreen extends StatefulWidget {
  final BahanPakanRepository? repository;
  final CsvPicker? pickCsv;
  final CsvShare? shareCsv;

  const MasterPakanScreen({
    super.key,
    this.repository,
    this.pickCsv,
    this.shareCsv,
  });

  @override
  State<MasterPakanScreen> createState() => _MasterPakanScreenState();
}

class _MasterPakanScreenState extends State<MasterPakanScreen> {
  static const _safeShareFallback = Rect.fromLTWH(0, 0, 1, 1);

  final _exportButtonKey = GlobalKey();

  late final BahanPakanRepository _repository;
  late final CsvPicker _pickCsv;
  late final CsvShare _shareCsv;

  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? BahanPakanRepository();
    _pickCsv = widget.pickCsv ?? _pickCsvDefault;
    _shareCsv = widget.shareCsv ?? _shareCsvDefault;
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

  Future<Uint8List> _readCsvBytes(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes != null) return bytes;

    final stream = file.readStream;
    if (stream != null) {
      final chunks = <int>[];
      await for (final chunk in stream) {
        chunks.addAll(chunk);
      }
      return Uint8List.fromList(chunks);
    }

    final path = file.path;
    if (path != null && path.isNotEmpty) {
      return XFile(path).readAsBytes();
    }

    throw const FormatException('Isi file CSV tidak tersedia untuk dibaca.');
  }

  Future<void> _imporCsv() async {
    if (_isLoading || _isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final file = await _pickCsv();
      if (file == null) return;

      final csv = utf8.decode(await _readCsvBytes(file));
      BahanPakanCsvCodec.parse(csv);
      if (!mounted) return;

      final konfirmasi = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Impor dan ganti database?'),
          content: const Text(
            'Semua data lama yang tidak ada di CSV akan dihapus permanen. Lanjutkan penggantian database pakan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Impor dan Ganti'),
            ),
          ],
        ),
      );

      if (konfirmasi != true) return;

      final hasil = await _repository.replaceFromCsv(csv);
      if (!mounted) return;
      setState(() {});
      _tampilkanPesanImpor(hasil);
    } catch (error) {
      if (!mounted) return;
      AppToast.showError(context, 'Gagal mengimpor CSV: $error');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _tampilkanPesanImpor(HasilImportBahanPakan hasil) {
    AppToast.showSuccess(
      context,
      'Impor berhasil. Ditambah: ${hasil.ditambah}. '
      'Diperbarui: ${hasil.diperbarui}. '
      'Dihapus: ${hasil.dihapus}.',
    );
  }

  Rect _sharePositionOrigin() {
    final renderObject = _exportButtonKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return _safeShareFallback;
    }
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  Future<void> _eksporCsv() async {
    if (_isLoading || _isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _shareCsv(_repository.dataAktif, _sharePositionOrigin());
    } catch (error) {
      if (!mounted) return;
      AppToast.showError(context, 'Gagal mengekspor CSV: $error');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _bukaFormBahan({BahanPakan? bahan}) async {
    if (_isLoading || _isProcessing) return;

    try {
      final hasil = await showModalBottomSheet<BahanPakan>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _FormBahanPakanSheet(
          initialData: bahan,
          nextId: bahan?.id ?? _repository.nextId(),
        ),
      );

      if (hasil == null || !mounted) return;
      setState(() => _isProcessing = true);

      if (bahan == null) {
        await _repository.addBahan(hasil);
        if (!mounted) return;
        AppToast.showSuccess(context, 'Bahan pakan baru berhasil disimpan.');
      } else {
        await _repository.updateBahan(bahan.id, hasil);
        if (!mounted) return;
        AppToast.showSuccess(context, 'Perubahan bahan pakan berhasil disimpan.');
      }

      if (mounted) setState(() {});
    } catch (error) {
      if (!mounted) return;
      AppToast.showError(context, 'Gagal menyimpan bahan pakan: $error');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _hapusBahan(BahanPakan bahan) async {
    if (_isLoading || _isProcessing) return;
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

    if (!mounted || konfirmasi != true) return;
    setState(() => _isProcessing = true);

    try {
      await _repository.removeBahan(bahan.id);
      if (!mounted) return;

      setState(() {});
      AppToast.showSuccess(context, 'Bahan pakan berhasil dihapus.');
    } catch (error) {
      if (!mounted) return;
      AppToast.showError(context, 'Gagal menghapus bahan pakan: $error');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _ubahStatusAktif(BahanPakan bahan, bool isActive) async {
    if (_isLoading || _isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await _repository.updateBahan(
        bahan.id,
        bahan.copyWith(isActive: isActive),
      );
      if (!mounted) return;
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      AppToast.showError(context, 'Gagal mengubah status bahan pakan: $error');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _resetDataAwal() async {
    if (_isLoading || _isProcessing) return;
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

    if (!mounted || konfirmasi != true) return;
    setState(() => _isProcessing = true);

    try {
      await _repository.resetKeDataAwal();
      if (!mounted) return;

      setState(() {});
      AppToast.showInfo(context, 'Master pakan dikembalikan ke data awal.');
    } catch (error) {
      if (!mounted) return;
      AppToast.showError(context, 'Gagal mereset master pakan: $error');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semuaData = _repository.semuaData;
    final totalAktif = semuaData.where((item) => item.isActive).length;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading || _isProcessing ? null : () => _bukaFormBahan(),
        backgroundColor: AppColors.accentOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Bahan'),
      ),
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(
            title: 'Database Pakan',
            subtitle: 'Katalog bahan pakan',
            actions: [
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              PopupMenuButton<String>(
                key: _exportButtonKey,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white,
                ),
                tooltip: 'Menu Opsi',
                enabled: !_isLoading && !_isProcessing,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (value) {
                  switch (value) {
                    case 'impor':
                      _imporCsv();
                      break;
                    case 'ekspor':
                      _eksporCsv();
                      break;
                    case 'reset':
                      _resetDataAwal();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'impor',
                    child: Row(
                      children: [
                        Icon(
                          Icons.file_upload_outlined,
                          size: 18,
                          color: AppColors.primaryBlue,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Impor CSV',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (defaultTargetPlatform != TargetPlatform.linux)
                    const PopupMenuItem(
                      value: 'ekspor',
                      child: Row(
                        children: [
                          Icon(
                            Icons.file_download_outlined,
                            size: 18,
                            color: AppColors.secondaryGreen,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ekspor CSV',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: AppColors.accentOrange,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reset ke Data Awal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_errorMessage!, textAlign: TextAlign.center),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),
                  _buildRingkasan(
                    totalSemua: semuaData.length,
                    totalAktif: totalAktif,
                  ),
                  const SizedBox(height: 16),
                  if (semuaData.isEmpty)
                    _buildEmptyState()
                  else
                    ...semuaData.map(_buildBahanCard),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRingkasan({required int totalSemua, required int totalAktif}) {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.secondaryGreen,
                  size: 20,
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Pakan',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '$totalSemua',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
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
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.accentGreen,
                  size: 20,
                ),
                const SizedBox(height: 8),
                Text(
                  'Bahan Aktif',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '$totalAktif',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
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
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.secondaryGreen.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          const Text(
            'Database Kosong',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Belum ada data bahan pakan yang tersimpan.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      bahan.kategori.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textGrey,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: bahan.isActive,
                activeThumbColor: AppColors.secondaryGreen,
                onChanged: _isLoading || _isProcessing
                    ? null
                    : (value) => _ubahStatusAktif(bahan, value),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric(
                'BK',
                '${IndonesianNumberFormatter.format(bahan.bk, decimals: 1)}%',
              ),
              _buildMetric(
                'PK',
                '${IndonesianNumberFormatter.format(bahan.protein, decimals: 1)}%',
              ),
              _buildMetric(
                'TDN',
                '${IndonesianNumberFormatter.format(bahan.tdn, decimals: 1)}%',
              ),
              _buildMetric(
                'Harga',
                'Rp${IndonesianNumberFormatter.format(bahan.hargaDefault, decimals: 0)}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: _isLoading || _isProcessing
                      ? null
                      : () => _bukaFormBahan(bahan: bahan),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton.icon(
                  onPressed: _isLoading || _isProcessing
                      ? null
                      : () => _hapusBahan(bahan),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                  ),
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
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _FormBahanPakanSheet extends StatefulWidget {
  final BahanPakan? initialData;
  final int nextId;

  const _FormBahanPakanSheet({required this.initialData, required this.nextId});

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
    _proteinController = TextEditingController(
      text: _formatNumber(data?.protein),
    );
    _tdnController = TextEditingController(text: _formatNumber(data?.tdn));
    _hargaController = TextEditingController(
      text: data == null
          ? ''
          : IndonesianNumberFormatter.format(data.hargaDefault, decimals: 0),
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
    return IndonesianNumberFormatter.format(
      value,
      decimals: value.truncateToDouble() == value ? 0 : 2,
    );
  }

  double? _tryParseNumber(String value) {
    final parsed = IndonesianNumberFormatter.tryParse(value);
    if (parsed == null || !parsed.isFinite || parsed < 0) return null;
    return parsed.toDouble();
  }

  String? _validasiAngka(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    final parsed = _tryParseNumber(value);
    if (parsed == null) {
      if (value.trim().startsWith('-')) return 'Tidak boleh negatif';
      return 'Angka tidak valid';
    }
    return null;
  }

  String? _validasiNama(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    if (BahanPakanCsvCodec.isFormulaLeadingName(value)) {
      return 'Nama tidak boleh diawali karakter formula';
    }
    return null;
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;

    final bk = _tryParseNumber(_bkController.text);
    final protein = _tryParseNumber(_proteinController.text);
    final tdn = _tryParseNumber(_tdnController.text);
    final harga = _tryParseNumber(_hargaController.text);
    if (bk == null || protein == null || tdn == null || harga == null) {
      return;
    }

    Navigator.pop(
      context,
      BahanPakan(
        id: widget.initialData?.id ?? widget.nextId,
        nama: _namaController.text.trim(),
        kategori: _selectedKategori!,
        bk: bk,
        abu: widget.initialData?.abu ?? 0,
        lemak: widget.initialData?.lemak ?? 0,
        serat: widget.initialData?.serat ?? 0,
        protein: protein,
        betn: widget.initialData?.betn ?? 0,
        tdn: tdn,
        me: widget.initialData?.me ?? 0,
        hargaDefault: harga,
        isActive: _isActive,
        ca: widget.initialData?.ca ?? 0,
        p: widget.initialData?.p ?? 0,
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
        keyboardType: TextInputType.text,
        validator: _validasiNama,
      ),
              const Text(
                'Kategori',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedKategori,
                hint: const Text('-- Pilih Kategori --'),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'hijauan', child: Text('Hijauan')),
                  DropdownMenuItem(
                    value: 'konsentrat',
                    child: Text('Konsentrat'),
                  ),
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
                      validator: _validasiAngka,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _proteinController,
                      label: 'PK (%)',
                      keyboardType: TextInputType.number,
                      validator: _validasiAngka,
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
                      validator: _validasiAngka,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _hargaController,
                      label: 'Harga /kg',
                      keyboardType: TextInputType.number,
                      validator: _validasiAngka,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Bahan Aktif'),
                subtitle: const Text(
                  'Muncul di pilihan kalkulasi',
                  style: TextStyle(fontSize: 12),
                ),
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
