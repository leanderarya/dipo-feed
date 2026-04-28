import '../../../data/models/kebutuhan_nutrien_sapi.dart';
import 'interpolasi_linear.dart';

class _DataBkLaktasi {
  final double fcm;
  final Map<int, double?> persenBkByBb;

  const _DataBkLaktasi({
    required this.fcm,
    required this.persenBkByBb,
  });
}

class _DataHidupPokok {
  final double bb;
  final double tdnKg;
  final double proteinGram;
  final double caGram;
  final double pGram;

  const _DataHidupPokok({
    required this.bb,
    required this.tdnKg,
    required this.proteinGram,
    required this.caGram,
    required this.pGram,
  });
}

class _DataProduksiFcm {
  final double lemakPersen;
  final double tdnKg;
  final double proteinGram;
  final double caGram;
  final double pGram;

  const _DataProduksiFcm({
    required this.lemakPersen,
    required this.tdnKg,
    required this.proteinGram,
    required this.caGram,
    required this.pGram,
  });
}

class PerhitunganKebutuhanLaktasiNrc1988 {
  // Mengikuti alur worksheet yang dipakai pada proyek ini:
  // 1. FCM dihitung dari produksi susu input.
  // 2. BK dicari lewat jalur kolom inti tabel (400, 500, 600) lalu diekstrapolasi ke BB target bila perlu.
  static const List<int> _kolomBbIntiBk = [400, 500, 600];

  static const List<_DataBkLaktasi> _tabelBk = [
    _DataBkLaktasi(
      fcm: 10,
      persenBkByBb: {
        300: 3.0,
        350: 2.9,
        400: 2.7,
        500: 2.4,
        600: 2.2,
      },
    ),
    _DataBkLaktasi(
      fcm: 15,
      persenBkByBb: {
        300: 3.6,
        350: 3.4,
        400: 3.2,
        500: 2.8,
        600: 2.6,
      },
    ),
    _DataBkLaktasi(
      fcm: 20,
      persenBkByBb: {
        300: null,
        350: null,
        400: 3.6,
        500: 3.2,
        600: 2.9,
      },
    ),
    _DataBkLaktasi(
      fcm: 25,
      persenBkByBb: {
        300: null,
        350: null,
        400: 4.0,
        500: 3.5,
        600: 3.2,
      },
    ),
    _DataBkLaktasi(
      fcm: 30,
      persenBkByBb: {
        300: null,
        350: null,
        400: 4.4,
        500: 3.9,
        600: 3.5,
      },
    ),
  ];

  static const List<_DataHidupPokok> _tabelHidupPokok = [
    _DataHidupPokok(
      bb: 300,
      tdnKg: 2.55,
      proteinGram: 272,
      caGram: 12,
      pGram: 7,
    ),
    _DataHidupPokok(
      bb: 350,
      tdnKg: 2.84,
      proteinGram: 295,
      caGram: 14,
      pGram: 9,
    ),
    _DataHidupPokok(
      bb: 400,
      tdnKg: 3.13,
      proteinGram: 318,
      caGram: 16,
      pGram: 11,
    ),
    _DataHidupPokok(
      bb: 450,
      tdnKg: 3.42,
      proteinGram: 341,
      caGram: 18,
      pGram: 13,
    ),
    _DataHidupPokok(
      bb: 500,
      tdnKg: 3.70,
      proteinGram: 364,
      caGram: 20,
      pGram: 14,
    ),
    _DataHidupPokok(
      bb: 550,
      tdnKg: 3.92,
      proteinGram: 386,
      caGram: 22,
      pGram: 16,
    ),
  ];

  static const List<_DataProduksiFcm> _tabelProduksi = [
    _DataProduksiFcm(
      lemakPersen: 3.0,
      tdnKg: 0.280,
      proteinGram: 78,
      caGram: 2.73,
      pGram: 1.68,
    ),
    _DataProduksiFcm(
      lemakPersen: 3.5,
      tdnKg: 0.301,
      proteinGram: 84,
      caGram: 2.97,
      pGram: 1.83,
    ),
    _DataProduksiFcm(
      lemakPersen: 4.0,
      tdnKg: 0.322,
      proteinGram: 90,
      caGram: 3.21,
      pGram: 1.98,
    ),
  ];

  static KebutuhanNutrienSapi hitung({
    required double beratBadan,
    required double produksiSusuLiter,
    required double lemakSusuPersen,
  }) {
    final catatan = <String>[];
    final kgSusu = produksiSusuLiter * 1.028;
    // Konversi kg susu tetap disimpan sebagai detail opsional,
    // tetapi basis FCM mengikuti angka produksi susu yang diinput pengguna.
    final fcm4 =
        (0.4 * produksiSusuLiter) +
        (15 * (lemakSusuPersen / 100) * produksiSusuLiter);

    final bkPersenBb = _hitungBkPersenBb(
      fcm4: fcm4,
      beratBadan: beratBadan,
      catatan: catatan,
    );
    final kebutuhanBkKg = (bkPersenBb / 100) * beratBadan;

    final tdnHidupPokokKg = _interpolasiHidupPokok(
      beratBadan,
      (item) => item.tdnKg,
      catatan: catatan,
    );
    final proteinHidupPokokGram = _interpolasiHidupPokok(
      beratBadan,
      (item) => item.proteinGram,
      catatan: catatan,
    );
    final caHidupPokokGram = _interpolasiHidupPokok(
      beratBadan,
      (item) => item.caGram,
      catatan: catatan,
    );
    final pHidupPokokGram = _interpolasiHidupPokok(
      beratBadan,
      (item) => item.pGram,
      catatan: catatan,
    );

    if (lemakSusuPersen < 2.5 || lemakSusuPersen > 4.0) {
      _tambahCatatan(
        catatan,
        'Lemak susu berada di luar rentang rekomendasi 2.5%–4.0%, hasil dihitung dengan ekstrapolasi.',
      );
    }

    final tdnPerKgFcm = _interpolasiProduksi(
      lemakSusuPersen,
      (item) => item.tdnKg,
      catatan: catatan,
    );
    final proteinPerKgFcm = _interpolasiProduksi(
      lemakSusuPersen,
      (item) => item.proteinGram,
      catatan: catatan,
    );
    final caPerKgFcm = _interpolasiProduksi(
      lemakSusuPersen,
      (item) => item.caGram,
      catatan: catatan,
    );
    final pPerKgFcm = _interpolasiProduksi(
      lemakSusuPersen,
      (item) => item.pGram,
      catatan: catatan,
    );

    final tdnProduksiKg = tdnPerKgFcm * fcm4;
    final proteinProduksiGram = proteinPerKgFcm * fcm4;
    final caProduksiGram = caPerKgFcm * fcm4;
    final pProduksiGram = pPerKgFcm * fcm4;

    final totalTdnKg = tdnHidupPokokKg + tdnProduksiKg;
    final totalProteinGram = proteinHidupPokokGram + proteinProduksiGram;
    final totalCaGram = caHidupPokokGram + caProduksiGram;
    final totalPGram = pHidupPokokGram + pProduksiGram;

    return KebutuhanNutrienSapi(
      kebutuhanBkKg: kebutuhanBkKg,
      kebutuhanProteinKg: totalProteinGram / 1000,
      kebutuhanTdnKg: totalTdnKg,
      kebutuhanCaGram: totalCaGram,
      kebutuhanPGram: totalPGram,
      detail: DetailKebutuhanNutrienSapi(
        kgSusu: kgSusu,
        fcm4: fcm4,
        bkPersenBb: bkPersenBb,
        tdnHidupPokokKg: tdnHidupPokokKg,
        proteinHidupPokokGram: proteinHidupPokokGram,
        caHidupPokokGram: caHidupPokokGram,
        pHidupPokokGram: pHidupPokokGram,
        tdnProduksiKg: tdnProduksiKg,
        proteinProduksiGram: proteinProduksiGram,
        caProduksiGram: caProduksiGram,
        pProduksiGram: pProduksiGram,
      ),
      catatan: catatan,
    );
  }

  static double _hitungBkPersenBb({
    required double fcm4,
    required double beratBadan,
    required List<String> catatan,
  }) {
    final hasilPerKolom = _kolomBbIntiBk.map((bbKolom) {
      final titikFcm = _tabelBk.map((baris) {
        return TitikLinear(
          x: baris.fcm,
          y: baris.persenBkByBb[bbKolom]!,
        );
      }).toList();

      if (fcm4 < titikFcm.first.x || fcm4 > titikFcm.last.x) {
        _tambahCatatan(
          catatan,
          'BK %BB pada BB $bbKolom menggunakan ekstrapolasi terhadap FCM karena nilai 4% FCM berada di luar rentang tabel.',
        );
      }

      return TitikLinear(
        x: bbKolom.toDouble(),
        y: interpolasiDariTitik(
          titik: titikFcm,
          xTarget: fcm4,
        ),
      );
    }).toList();

    if (beratBadan < hasilPerKolom.first.x || beratBadan > hasilPerKolom.last.x) {
      _tambahCatatan(
        catatan,
        'BK %BB menggunakan ekstrapolasi terhadap BB dari kolom tabel inti karena berada di luar area data utama.',
      );
    }

    return interpolasiDariTitik(
      titik: hasilPerKolom,
      xTarget: beratBadan,
    );
  }

  static double _interpolasiHidupPokok(
    double beratBadan,
    double Function(_DataHidupPokok item) selector, {
    required List<String> catatan,
  }) {
    if (beratBadan < _tabelHidupPokok.first.bb ||
        beratBadan > _tabelHidupPokok.last.bb) {
      _tambahCatatan(
        catatan,
        'Kebutuhan hidup pokok menggunakan ekstrapolasi terhadap BB karena berada di luar rentang tabel.',
      );
    }

    return interpolasiDariTitik(
      titik: _tabelHidupPokok
          .map((item) => TitikLinear(x: item.bb, y: selector(item)))
          .toList(),
      xTarget: beratBadan,
    );
  }

  static double _interpolasiProduksi(
    double lemakSusuPersen,
    double Function(_DataProduksiFcm item) selector, {
    required List<String> catatan,
  }) {
    if (lemakSusuPersen < _tabelProduksi.first.lemakPersen ||
        lemakSusuPersen > _tabelProduksi.last.lemakPersen) {
      _tambahCatatan(
        catatan,
        'Kebutuhan produksi menggunakan ekstrapolasi terhadap persen lemak susu.',
      );
    }

    return interpolasiDariTitik(
      titik: _tabelProduksi
          .map(
            (item) => TitikLinear(
              x: item.lemakPersen,
              y: selector(item),
            ),
          )
          .toList(),
      xTarget: lemakSusuPersen,
    );
  }

  static void _tambahCatatan(List<String> catatan, String pesan) {
    if (!catatan.contains(pesan)) {
      catatan.add(pesan);
    }
  }
}
