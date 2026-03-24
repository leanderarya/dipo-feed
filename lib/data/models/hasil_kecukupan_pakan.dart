class KebutuhanNutrisiSapi {
  final double kebutuhanBkKg;
  final double kebutuhanMe;
  final double kebutuhanProtein;
  final double kebutuhanTdn;

  const KebutuhanNutrisiSapi({
    required this.kebutuhanBkKg,
    required this.kebutuhanMe,
    required this.kebutuhanProtein,
    required this.kebutuhanTdn,
  });
}

class DetailEvaluasiNutrisi {
  final double kebutuhan;
  final double pemberian;
  final double selisih;

  const DetailEvaluasiNutrisi({
    required this.kebutuhan,
    required this.pemberian,
    required this.selisih,
  });

  String get status {
    if (selisih > 0.0001) return 'Berlebih';
    if (selisih < -0.0001) return 'Kurang';
    return 'Cukup';
  }
}

class HasilEvaluasiKecukupan {
  final DetailEvaluasiNutrisi bk;
  final DetailEvaluasiNutrisi protein;
  final DetailEvaluasiNutrisi tdn;
  final DetailEvaluasiNutrisi me;

  const HasilEvaluasiKecukupan({
    required this.bk,
    required this.protein,
    required this.tdn,
    required this.me,
  });

  String get kesimpulanUmum {
    final semuaStatus = [
      bk.status,
      protein.status,
      tdn.status,
      me.status,
    ];

    if (semuaStatus.every((status) => status == 'Cukup')) {
      return 'Pakan yang diberikan sudah sesuai dengan kebutuhan sapi.';
    }

    if (semuaStatus.any((status) => status == 'Kurang')) {
      return 'Pakan yang diberikan belum mencukupi seluruh kebutuhan nutrisi sapi.';
    }

    return 'Pakan yang diberikan cenderung berlebih pada beberapa komponen nutrisi.';
  }
}