import '../../../data/models/fisiologi_sapi.dart';
import 'evaluasi_standar_nutrien.dart';

class NarasiEvaluasiStandarGenerator {
  static List<String> buatNarasi({
    required FisiologiSapi fisiologi,
    required List<EvaluasiStandarNutrienItem> items,
  }) {
    final kurang = items
        .where((item) => item.status == StatusStandarNutrien.kurang)
        .map((item) => item.label)
        .toList();
    final berlebih = items
        .where((item) => item.status == StatusStandarNutrien.berlebih)
        .map((item) => item.label)
        .toList();

    final hasil = <String>[];
    if (kurang.isNotEmpty) {
      hasil.add('Perlu ditingkatkan: ${_gabungLabel(kurang)}.');
    }
    if (berlebih.isNotEmpty) {
      hasil.add('Perlu dikurangi: ${_gabungLabel(berlebih)}.');
    }
    if (hasil.isEmpty) {
      hasil.add('Komposisi utama sudah mendekati standar.');
    }
    return hasil;
  }

  static String buatKesimpulan({
    required FisiologiSapi fisiologi,
    required List<EvaluasiStandarNutrienItem> items,
  }) {
    final labelFisiologi = _labelFisiologi(fisiologi).toLowerCase();
    final kurang = items
        .where((item) => item.status == StatusStandarNutrien.kurang)
        .map((item) => item.label)
        .toList();
    final berlebih = items
        .where((item) => item.status == StatusStandarNutrien.berlebih)
        .map((item) => item.label)
        .toList();

    if (kurang.isEmpty && berlebih.isEmpty) {
      return 'Secara umum campuran pakan sudah memenuhi sebagian besar standar nutrien untuk sapi $labelFisiologi.';
    }

    if (kurang.isNotEmpty && berlebih.isEmpty) {
      return 'Secara umum campuran pakan sudah cukup baik, namun ${_gabungLabel(kurang)} masih perlu ditingkatkan.';
    }

    if (kurang.isEmpty && berlebih.isNotEmpty) {
      return 'Secara umum campuran pakan telah memenuhi beberapa standar, namun ${_gabungLabel(berlebih)} masih cenderung berlebih.';
    }

    return 'Secara umum campuran pakan masih perlu perbaikan karena ${_gabungLabel(kurang)} masih kurang dan ${_gabungLabel(berlebih)} cenderung berlebih.';
  }

  static String _labelFisiologi(FisiologiSapi fisiologi) {
    switch (fisiologi) {
      case FisiologiSapi.dara:
        return 'Dara';
      case FisiologiSapi.laktasi:
        return 'Laktasi';
      case FisiologiSapi.keringKandang:
        return 'Kering Kandang';
    }
  }

  static String _gabungLabel(List<String> labels) {
    if (labels.length == 1) return labels.first;
    if (labels.length == 2) return '${labels.first} dan ${labels.last}';
    return '${labels.sublist(0, labels.length - 1).join(', ')}, dan ${labels.last}';
  }
}
