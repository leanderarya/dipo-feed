// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bahan_pakan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BahanPakanAdapter extends TypeAdapter<BahanPakan> {
  @override
  final int typeId = 0;

  @override
  BahanPakan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    // Support both old format (15 fields, kategori at index 2)
    // and new format (14 fields, no kategori)
    if (numOfFields == 15) {
      // Old: 0=id,1=nama,2=kategori(skip),3=bk,4=abu,5=lemak,6=serat,
      //      7=protein,8=betn,9=tdn,10=me,11=hargaDefault,12=isActive,
      //      13=ca,14=p
      return BahanPakan(
        id: fields[0] as int,
        nama: fields[1] as String,
        bk: fields[3] as double,
        abu: fields[4] as double,
        lemak: fields[5] as double,
        serat: fields[6] as double,
        protein: fields[7] as double,
        betn: fields[8] as double,
        tdn: fields[9] as double,
        me: fields[10] as double,
        hargaDefault: fields[11] as double,
        isActive: fields[12] as bool,
        ca: (fields[13] as double?) ?? 0,
        p: (fields[14] as double?) ?? 0,
      );
    }
    return BahanPakan(
      id: fields[0] as int,
      nama: fields[1] as String,
      bk: fields[2] as double,
      abu: fields[3] as double,
      lemak: fields[4] as double,
      serat: fields[5] as double,
      protein: fields[6] as double,
      betn: fields[7] as double,
      tdn: fields[8] as double,
      me: fields[9] as double,
      hargaDefault: fields[10] as double,
      isActive: fields[11] as bool,
      ca: (fields[12] as double?) ?? 0,
      p: (fields[13] as double?) ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, BahanPakan obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nama)
      // Index 2 (was kategori) removed
      ..writeByte(2)
      ..write(obj.bk)
      ..writeByte(3)
      ..write(obj.abu)
      ..writeByte(4)
      ..write(obj.lemak)
      ..writeByte(5)
      ..write(obj.serat)
      ..writeByte(6)
      ..write(obj.protein)
      ..writeByte(7)
      ..write(obj.betn)
      ..writeByte(8)
      ..write(obj.tdn)
      ..writeByte(9)
      ..write(obj.me)
      ..writeByte(10)
      ..write(obj.hargaDefault)
      ..writeByte(11)
      ..write(obj.isActive)
      ..writeByte(12)
      ..write(obj.ca)
      ..writeByte(13)
      ..write(obj.p);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BahanPakanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}