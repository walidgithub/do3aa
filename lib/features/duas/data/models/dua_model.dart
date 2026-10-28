import '../../domain/entities/dua.dart';

class DuaModel extends Dua {
  const DuaModel({
    super.id,
    required super.text,
    required super.sortOrder,
    required super.isDefault,
    required super.createdAt,
    required super.updatedAt,
  });

  factory DuaModel.fromMap(Map<String, dynamic> map) {
    return DuaModel(
      id: map['id'] as int?,
      text: map['text'] as String,
      sortOrder: map['sort_order'] as int,
      isDefault: map['is_default'] == 1,
      createdAt: DateTime.parse(
        map['created_at'] as String,
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] as String,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'sort_order': sortOrder,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DuaModel.fromEntity(Dua dua) {
    return DuaModel(
      id: dua.id,
      text: dua.text,
      sortOrder: dua.sortOrder,
      isDefault: dua.isDefault,
      createdAt: dua.createdAt,
      updatedAt: dua.updatedAt,
    );
  }
}