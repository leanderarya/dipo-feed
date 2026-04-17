import '../models/bahan_pakan.dart';
import 'bahan_pakan_local_source.dart';

class BahanPakanRepository {
  static final BahanPakanRepository _instance = BahanPakanRepository._internal();
  factory BahanPakanRepository() => _instance;
  BahanPakanRepository._internal();

  final List<BahanPakan> _bahanPakan = [];
  bool _isInitialized = false;
  final BahanPakanLocalSource _source = BahanPakanLocalSource();

  List<BahanPakan> get dataAktif =>
      List.unmodifiable(_bahanPakan.where((bahan) => bahan.isActive));
  List<BahanPakan> get data => dataAktif;
  List<BahanPakan> get semuaData => List.unmodifiable(_bahanPakan);

  Future<void> initialize() async {
    if (_isInitialized) return;

    final data = await _source.ambilSemuaBahanPakan();
    _bahanPakan
      ..clear()
      ..addAll(data);
    _isInitialized = true;
  }

  Future<void> refresh() async {
    final data = await _source.ambilSemuaBahanPakan();
    _bahanPakan
      ..clear()
      ..addAll(data);
    _isInitialized = true;
  }

  Future<void> addBahan(BahanPakan bahan) async {
    await initialize();
    _bahanPakan.add(bahan);
    await _source.simpanSemuaBahanPakan(_bahanPakan);
  }

  Future<void> updateBahan(int id, BahanPakan updatedBahan) async {
    await initialize();
    final index = _bahanPakan.indexWhere((b) => b.id == id);
    if (index != -1) {
      _bahanPakan[index] = updatedBahan;
      await _source.simpanSemuaBahanPakan(_bahanPakan);
    }
  }

  Future<void> removeBahan(int id) async {
    await initialize();
    _bahanPakan.removeWhere((b) => b.id == id);
    await _source.simpanSemuaBahanPakan(_bahanPakan);
  }

  Future<void> resetKeDataAwal() async {
    await _source.resetKeDataAwal();
    await refresh();
  }

  int nextId() {
    if (_bahanPakan.isEmpty) return 1;
    return _bahanPakan
            .map((bahan) => bahan.id)
            .reduce((current, next) => current > next ? current : next) +
        1;
  }
}
