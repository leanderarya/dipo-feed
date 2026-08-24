import 'package:flutter/material.dart';

import '../../../data/models/campuran_pakan_item.dart';
import '../../../data/models/fisiologi_sapi.dart';
import '../../../data/models/kebutuhan_nutrien_sapi.dart';
import '../../cek_kandungan_nutrisi/logic/perhitungan_nutrisi.dart';

const List<Color> feedPaletteColors = [
  Color(0xFF2E7D32), // Green
  Color(0xFFF57F17), // Amber / Yellow
  Color(0xFF1976D2), // Blue
  Color(0xFFD84315), // Deep Orange
  Color(0xFF7B1FA2), // Purple
  Color(0xFF00838F), // Teal / Cyan
  Color(0xFFC2185B), // Pink
  Color(0xFF5D4037), // Brown
];

Color getFeedColor(int index) =>
    feedPaletteColors[index % feedPaletteColors.length];

class KontribusiNutrisiBahanPakan {
  final CampuranPakanItem item;
  final double bkKg;
  final double pkKg;
  final double tdnKg;
  final Color warna;

  const KontribusiNutrisiBahanPakan({
    required this.item,
    required this.bkKg,
    required this.pkKg,
    required this.tdnKg,
    required this.warna,
  });

  factory KontribusiNutrisiBahanPakan.fromItem(
    CampuranPakanItem item, {
    int index = 0,
  }) {
    final asFed = item.jumlahKg;
    final bkKg = asFed * (item.bahan.bk / 100);
    final pkKg = asFed * (item.bahan.protein / 100);
    final tdnKg = asFed * (item.bahan.tdn / 100);

    return KontribusiNutrisiBahanPakan(
      item: item,
      bkKg: bkKg,
      pkKg: pkKg,
      tdnKg: tdnKg,
      warna: getFeedColor(index),
    );
  }
}

class SegmenKontribusiNutrien {
  final String namaBahan;
  final double nilaiKg;
  final Color warna;

  const SegmenKontribusiNutrien({
    required this.namaBahan,
    required this.nilaiKg,
    required this.warna,
  });
}

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
  final List<SegmenKontribusiNutrien> segmen;

  const EvaluasiKecukupanItem({
    required this.nama,
    required this.singkatan,
    required this.kebutuhan,
    required this.pemberian,
    required this.satuan,
    this.segmen = const [],
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
  final List<KontribusiNutrisiBahanPakan> kontribusiBahan;

  const HasilEvaluasiKecukupanNutrien({
    required this.fisiologi,
    required this.items,
    required this.bk,
    required this.protein,
    required this.tdn,
    required this.ca,
    required this.p,
    this.kontribusiBahan = const [],
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
    List<CampuranPakanItem>? daftarPemberian,
  }) {
    final totalBerat = nutrisiPemberian.totalBerat;
    final bkKg = totalBerat * (nutrisiPemberian.bk / 100);
    final pkKg = totalBerat * (nutrisiPemberian.protein / 100);
    final tdnKg = totalBerat * (nutrisiPemberian.tdn / 100);
    // Data Ca dan P pada master bahan pakan belum terisi, pemberian dicatat 0.
    const caGram = 0.0;
    const pGram = 0.0;

    final kontribusiList = <KontribusiNutrisiBahanPakan>[];
    final segmenBk = <SegmenKontribusiNutrien>[];
    final segmenPk = <SegmenKontribusiNutrien>[];
    final segmenTdn = <SegmenKontribusiNutrien>[];

    if (daftarPemberian != null) {
      for (var i = 0; i < daftarPemberian.length; i++) {
        final item = daftarPemberian[i];
        if (item.jumlahKg > 0) {
          final kontribusi = KontribusiNutrisiBahanPakan.fromItem(item, index: i);
          kontribusiList.add(kontribusi);

          if (kontribusi.bkKg > 0) {
            segmenBk.add(
              SegmenKontribusiNutrien(
                namaBahan: item.bahan.nama,
                nilaiKg: kontribusi.bkKg,
                warna: kontribusi.warna,
              ),
            );
          }
          if (kontribusi.pkKg > 0) {
            segmenPk.add(
              SegmenKontribusiNutrien(
                namaBahan: item.bahan.nama,
                nilaiKg: kontribusi.pkKg,
                warna: kontribusi.warna,
              ),
            );
          }
          if (kontribusi.tdnKg > 0) {
            segmenTdn.add(
              SegmenKontribusiNutrien(
                namaBahan: item.bahan.nama,
                nilaiKg: kontribusi.tdnKg,
                warna: kontribusi.warna,
              ),
            );
          }
        }
      }
    }

    final bkItem = EvaluasiKecukupanItem(
      nama: 'Bahan Kering',
      singkatan: 'BK',
      kebutuhan: kebutuhan.kebutuhanBkKg,
      pemberian: bkKg,
      satuan: 'kg',
      segmen: segmenBk,
    );

    final pkItem = EvaluasiKecukupanItem(
      nama: 'Protein Kasar',
      singkatan: 'PK',
      kebutuhan: kebutuhan.kebutuhanProteinKg,
      pemberian: pkKg,
      satuan: 'kg',
      segmen: segmenPk,
    );

    final tdnItem = EvaluasiKecukupanItem(
      nama: 'Total Digestible Nutrients',
      singkatan: 'TDN',
      kebutuhan: kebutuhan.kebutuhanTdnKg,
      pemberian: tdnKg,
      satuan: 'kg',
      segmen: segmenTdn,
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
      kontribusiBahan: kontribusiList,
    );
  }
}
