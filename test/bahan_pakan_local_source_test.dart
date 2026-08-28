import 'dart:convert';
import 'dart:io';
import 'package:dipo_feed/data/models/bahan_pakan.dart';
import 'package:dipo_feed/data/sources/bahan_pakan_local_source.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

const _assetChannel = 'flutter/assets';
const _canonicalNames = [
  'Pollard Tongkat',
  'Pollard Manunggal',
  'Pellet NuFeed',
  'Konsentrat Mixfeed',
  'Singkong',
  'Rumput Lapang',
  'Rumput Gajah',
  'Rumput Odot',
  'Rumput Pakchong',
  'Daun Singkong',
  'Daun Pepaya',
  'Batang Pepaya',
  'Pepaya + Singkong Batang',
  'Pollard Kepala Kuda',
  'Bekatul',
  'Konsentrat Fermentasi',
  'Pellet Wilmar',
  'Ampas Tahu',
  'Jerami Padi Kering',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void mockAsset(String content) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          _assetChannel,
          (_) async =>
              ByteData.sublistView(Uint8List.fromList(utf8.encode(content))),
        );
    rootBundle.evict('assets/data/bahan_pakan.csv');
  }

  void clearAssetMock() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(_assetChannel, null);
    rootBundle.evict('assets/data/bahan_pakan.csv');
  }

  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('bahan_pakan_test');
    Hive.init(hiveDirectory.path);
    Hive.registerAdapter(BahanPakanAdapter());
    await Hive.openBox<BahanPakan>('bahan_pakan_box');
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('loads canonical CSV rows into deterministic active records', () async {
    final data = await BahanPakanLocalSource().ambilBahanPakanAwal();

    expect(data, hasLength(19));
    expect(
      data.map((bahan) => bahan.id),
      orderedEquals(List.generate(19, (index) => index + 1)),
    );
    expect(data.every((bahan) => bahan.isActive), isTrue);
    expect(data.where((bahan) => bahan.kategori == 'energi'), isEmpty);
    expect(data.where((bahan) => bahan.kategori == 'limbah'), isEmpty);
    expect(data.map((bahan) => bahan.nama), orderedEquals(_canonicalNames));

    expect(data.first.kategori, 'konsentrat');
    expect(data.first.bk, 86.63);
    expect(data.first.abu, 4.49);
    expect(data.first.lemak, 4.85);
    expect(data.first.serat, 9.29);
    expect(data.first.protein, 13.47);
    expect(data.first.betn, 67.90);
    expect(data.first.tdn, 79.25);
    expect(data.first.me, 11.97);
    expect(data.first.hargaDefault, 4500);
    expect(data.first.ca, 0);
    expect(data.first.p, 0);

    expect(
      data.singleWhere((bahan) => bahan.nama == 'Singkong').kategori,
      'lainnya',
    );
    expect(
      data.singleWhere((bahan) => bahan.nama == 'Ampas Tahu').kategori,
      'lainnya',
    );
  });

  test('rejects an empty canonical CSV seed', () async {
    mockAsset('nama;harga;kategori;BK;abu;lemak;serat;PK;BETN;TDN;ME;Ca;P');

    try {
      await expectLater(
        BahanPakanLocalSource().ambilBahanPakanAwal(),
        throwsFormatException,
      );
    } finally {
      clearAssetMock();
    }
  });

  test('simpan restores Hive values after a partial write failure', () async {
    const previous = BahanPakan(
      id: 1,
      nama: 'Data Lama',
      kategori: 'lainnya',
      bk: 1,
      abu: 1,
      lemak: 1,
      serat: 1,
      protein: 1,
      betn: 1,
      tdn: 1,
      me: 1,
      hargaDefault: 1,
      isActive: true,
    );
    const replacement = BahanPakan(
      id: 2,
      nama: 'Data Baru',
      kategori: 'hijauan',
      bk: 2,
      abu: 2,
      lemak: 2,
      serat: 2,
      protein: 2,
      betn: 2,
      tdn: 2,
      me: 2,
      hargaDefault: 2,
      isActive: true,
    );
    await BahanPakanLocalSource().simpanSemuaBahanPakan([previous]);
    var fail = true;
    final source = BahanPakanLocalSource(
      writeOperation: (data) async {
        final box = Hive.box<BahanPakan>('bahan_pakan_box');
        await box.clear();
        await box.add(data.single);
        if (fail) {
          fail = false;
          throw StateError('write failed');
        }
      },
    );

    await expectLater(
      source.simpanSemuaBahanPakan([replacement]),
      throwsStateError,
    );

    expect(
      Hive.box<BahanPakan>(
        'bahan_pakan_box',
      ).values.map((item) => item.toJson()),
      [previous.toJson()],
    );
  });

  test('writeOperation receives immutable data', () async {
    final source = BahanPakanLocalSource(
      writeOperation: (data) async {
        data.add(
          const BahanPakan(
            id: 2,
            nama: 'Data Baru',
            kategori: 'hijauan',
            bk: 2,
            abu: 2,
            lemak: 2,
            serat: 2,
            protein: 2,
            betn: 2,
            tdn: 2,
            me: 2,
            hargaDefault: 2,
            isActive: true,
          ),
        );
      },
    );

    await expectLater(
      source.simpanSemuaBahanPakan([
        const BahanPakan(
          id: 1,
          nama: 'Data Lama',
          kategori: 'lainnya',
          bk: 1,
          abu: 1,
          lemak: 1,
          serat: 1,
          protein: 1,
          betn: 1,
          tdn: 1,
          me: 1,
          hargaDefault: 1,
          isActive: true,
        ),
      ]),
      throwsUnsupportedError,
    );
  });

  test(
    'normalizes and persists legacy categories when loading existing data',
    () async {
      const legacyEnergy = BahanPakan(
        id: 90,
        nama: 'Energi Lama',
        kategori: 'energi',
        bk: 1,
        abu: 1,
        lemak: 1,
        serat: 1,
        protein: 1,
        betn: 1,
        tdn: 1,
        me: 1,
        hargaDefault: 1,
        isActive: true,
      );
      final legacyWaste = legacyEnergy.copyWith(
        id: 91,
        nama: 'Limbah Lama',
        kategori: 'limbah',
      );
      final source = BahanPakanLocalSource();
      await source.simpanSemuaBahanPakan([legacyEnergy, legacyWaste]);

      final data = await source.ambilSemuaBahanPakan();
      final persisted = Hive.box<BahanPakan>('bahan_pakan_box').values.toList();

      expect(data.map((bahan) => bahan.kategori), ['lainnya', 'lainnya']);
      expect(persisted.map((bahan) => bahan.kategori), ['lainnya', 'lainnya']);
      expect(data.map((bahan) => bahan.id), [90, 91]);
    },
  );

  test('reset reloads complete canonical CSV data', () async {
    final source = BahanPakanLocalSource();
    await source.simpanSemuaBahanPakan([
      const BahanPakan(
        id: 99,
        nama: 'Data Lama',
        kategori: 'lainnya',
        bk: 1,
        abu: 1,
        lemak: 1,
        serat: 1,
        protein: 1,
        betn: 1,
        tdn: 1,
        me: 1,
        hargaDefault: 1,
        isActive: false,
      ),
    ]);

    await source.resetKeDataAwal();
    final data = Hive.box<BahanPakan>('bahan_pakan_box').values.toList();

    expect(data, hasLength(19));
    expect(data.map((bahan) => bahan.nama), orderedEquals(_canonicalNames));
    expect(
      data.map((bahan) => bahan.id),
      orderedEquals(List.generate(19, (index) => index + 1)),
    );
    expect(data.every((bahan) => bahan.isActive), isTrue);
    expect(data.first.kategori, 'konsentrat');
    expect(data.first.bk, 86.63);
    expect(data.first.protein, 13.47);
    expect(data.first.hargaDefault, 4500);
    expect(data.last.kategori, 'hijauan');
    expect(data.last.bk, 39.79);
    expect(data.last.protein, 5.26);
    expect(data.last.hargaDefault, 4000);
    expect(
      data.singleWhere((bahan) => bahan.nama == 'Singkong').kategori,
      'lainnya',
    );
    expect(
      data.singleWhere((bahan) => bahan.nama == 'Ampas Tahu').kategori,
      'lainnya',
    );
  });
}
