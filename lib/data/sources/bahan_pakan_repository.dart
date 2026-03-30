import '../models/bahan_pakan.dart';
import 'bahan_pakan_local_source.dart';

class BahanPakanRepository {
  static final BahanPakanRepository _instance = BahanPakanRepository._internal();
  factory BahanPakanRepository() => _instance;
  BahanPakanRepository._internal();

  final List<BahanPakan> _bahanPakan = [];
  bool _isInitialized = false;

  List<BahanPakan> get data => List.unmodifiable(_bahanPakan);

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final source = BahanPakanLocalSource();
      final data = await source.ambilSemuaBahanPakan();
      _bahanPakan.clear();
      _bahanPakan.addAll(data);
      _isInitialized = true;
    } catch (e) {
      // ignore
    }
  }

  void addBahan(BahanPakan bahan) {
    _bahanPakan.add(bahan);
  }

  void updateBahan(int id, BahanPakan updatedBahan) {
    final index = _bahanPakan.indexWhere((b) => b.id == id);
    if (index != -1) {
      _bahanPakan[index] = updatedBahan;
    }
  }

  void removeBahan(int id) {
    _bahanPakan.removeWhere((b) => b.id == id);
  }
}
