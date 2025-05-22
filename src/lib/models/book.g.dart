// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookAdapter extends TypeAdapter<Book> {
  @override
  final int typeId = 0;

  @override
  Book read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Book(
      id: fields[0] as String?,
      title: fields[1] as String,
      author: fields[2] as String?,
      filePath: fields[3] as String,
      format: fields[4] as BookFormat,
      coverImagePath: fields[5] as String?,
      dateAdded: fields[6] as DateTime?,
      lastRead: fields[7] as DateTime?,
      readingPercentage: fields[8] as double,
      lastLocation: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.filePath)
      ..writeByte(4)
      ..write(obj.format)
      ..writeByte(5)
      ..write(obj.coverImagePath)
      ..writeByte(6)
      ..write(obj.dateAdded)
      ..writeByte(7)
      ..write(obj.lastRead)
      ..writeByte(8)
      ..write(obj.readingPercentage)
      ..writeByte(9)
      ..write(obj.lastLocation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BookFormatAdapter extends TypeAdapter<BookFormat> {
  @override
  final int typeId = 1;

  @override
  BookFormat read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return BookFormat.epub;
      case 1:
        return BookFormat.pdf;
      case 2:
        return BookFormat.mobi;
      case 3:
        return BookFormat.txt;
      case 4:
        return BookFormat.html;
      case 5:
        return BookFormat.unknown;
      default:
        return BookFormat.epub;
    }
  }

  @override
  void write(BinaryWriter writer, BookFormat obj) {
    switch (obj) {
      case BookFormat.epub:
        writer.writeByte(0);
        break;
      case BookFormat.pdf:
        writer.writeByte(1);
        break;
      case BookFormat.mobi:
        writer.writeByte(2);
        break;
      case BookFormat.txt:
        writer.writeByte(3);
        break;
      case BookFormat.html:
        writer.writeByte(4);
        break;
      case BookFormat.unknown:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookFormatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
