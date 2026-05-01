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
    return BahanPakan(
      id: fields[0] as int,
      nama: fields[1] as String,
      kategori: fields[2] as String,
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

  @override
  void write(BinaryWriter writer, BahanPakan obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nama)
      ..writeByte(2)
      ..write(obj.kategori)
      ..writeByte(3)
      ..write(obj.bk)
      ..writeByte(4)
      ..write(obj.abu)
      ..writeByte(5)
      ..write(obj.lemak)
      ..writeByte(6)
      ..write(obj.serat)
      ..writeByte(7)
      ..write(obj.protein)
      ..writeByte(8)
      ..write(obj.betn)
      ..writeByte(9)
      ..write(obj.tdn)
      ..writeByte(10)
      ..write(obj.me)
      ..writeByte(11)
      ..write(obj.hargaDefault)
      ..writeByte(12)
      ..write(obj.isActive)
      ..writeByte(13)
      ..write(obj.ca)
      ..writeByte(14)
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
