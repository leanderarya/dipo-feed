import '../../../data/models/fisiologi_sapi.dart';
import '../../../data/models/kebutuhan_nutrien_sapi.dart';
import '../../cek_kandungan_nutrisi/logic/perhitungan_nutrisi.dart';

enum StatusKecukupanNutrien {
  kurang,
  pas,
  berlebih;

  String get label {
    switch (this) {
      case StatusKecukupanNutrien.kurang:
        return 'Kurang';
      case StatusKecukupanNutrien.pas:
        return 'Pas';
      case StatusKecukupanNutrien.berlebih:
        return 'Berlebih';
    }
  }
}

class EvaluasiKecukupanItem {
  final String nama;
  final String singkatan;
  final double kebutuhan;
  final double pemberian;
  final String satuan;

  const EvaluasiKecukupanItem({
    required this.nama,
    required this.singkatan,
    required this.kebutuhan,
    required this.pemberian,
    required this.satuan,
  });

  String get labelLengkap => '$singkatan ($nama)';

  double get selisih => pemberian - kebutuhan;

  double get persentase =>
      kebutuhan > 0 ? (pemberian / kebutuhan).clamp(0.0, 2.0) : 0.0;

  StatusKecukupanNutrien get status {
    if (kebutuhan <= 0) {
      return pemberian > 0
          ? StatusKecukupanNutrien.berlebih
          : StatusKecukupanNutrien.pas;
    }
    if (pemberian < kebutuhan * 0.95) {
      return StatusKecukupanNutrien.kurang;
    }
    if (pemberian > kebutuhan * 1.05) {
      return StatusKecukupanNutrien.berlebih;
    }
    return StatusKecukupanNutrien.pas;
  }
}

class HasilEvaluasiKecukupanNutrien {
  final FisiologiSapi fisiologi;
  final List<EvaluasiKecukupanItem> items;
  final EvaluasiKecukupanItem bk;
  final EvaluasiKecukupanItem protein;
  final EvaluasiKecukupanItem tdn;
  final EvaluasiKecukupanItem ca;
  final EvaluasiKecukupanItem p;

  const HasilEvaluasiKecukupanNutrien({
    required this.fisiologi,
    required this.items,
    required this.bk,
    required this.protein,
    required this.tdn,
    required this.ca,
    required this.p,
  });

  String get kesimpulanUmum {
    final statusList = items.map((e) => e.status).toList();

    if (statusList.every((status) => status == StatusKecukupanNutrien.pas)) {
      return 'Pakan yang diberikan sudah sesuai dengan kebutuhan nutrien sapi.';
    }

    if (statusList.any((status) => status == StatusKecukupanNutrien.kurang)) {
      return 'Pakan yang diberikan belum mencukupi seluruh kebutuhan nutrien sapi.';
    }

    return 'Pakan yang diberikan cenderung berlebih pada beberapa komponen nutrien.';
  }

  static HasilEvaluasiKecukupanNutrien hitung({
    required FisiologiSapi fisiologi,
    required KebutuhanNutrienSapi kebutuhan,
    required HasilPerhitunganNutrisi nutrisiPemberian,
  }) {
    final totalBerat = nutrisiPemberian.totalBerat;
    final bkKg = totalBerat * (nutrisiPemberian.bk / 100);
    final pkKg = totalBerat * (nutrisiPemberian.protein / 100);
    final tdnKg = totalBerat * (nutrisiPemberian.tdn / 100);
    // Data Ca dan P pada master bahan pakan belum terisi, pemberian dicatat 0.
    const caGram = 0.0;
    const pGram = 0.0;

    final bkItem = EvaluasiKecukupanItem(
      nama: 'Bahan Kering',
      singkatan: 'BK',
      kebutuhan: kebutuhan.kebutuhanBkKg,
      pemberian: bkKg,
      satuan: 'kg',
    );

    final pkItem = EvaluasiKecukupanItem(
      nama: 'Protein Kasar',
      singkatan: 'PK',
      kebutuhan: kebutuhan.kebutuhanProteinKg,
      pemberian: pkKg,
      satuan: 'kg',
    );

    final tdnItem = EvaluasiKecukupanItem(
      nama: 'Total Digestible Nutrients',
      singkatan: 'TDN',
      kebutuhan: kebutuhan.kebutuhanTdnKg,
      pemberian: tdnKg,
      satuan: 'kg',
    );

    final caItem = EvaluasiKecukupanItem(
      nama: 'Kalsium',
      singkatan: 'Ca',
      kebutuhan: kebutuhan.kebutuhanCaGram,
      pemberian: caGram,
      satuan: 'g',
    );

    final pItem = EvaluasiKecukupanItem(
      nama: 'Fosfor',
      singkatan: 'P',
      kebutuhan: kebutuhan.kebutuhanPGram,
      pemberian: pGram,
      satuan: 'g',
    );

    return HasilEvaluasiKecukupanNutrien(
      fisiologi: fisiologi,
      items: [bkItem, pkItem, tdnItem, caItem, pItem],
      bk: bkItem,
      protein: pkItem,
      tdn: tdnItem,
      ca: caItem,
      p: pItem,
    );
  }
}
