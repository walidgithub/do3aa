import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/database/app_database.dart';
import '../models/dua_model.dart';

class DuaLocalDataSource {
  final AppDatabase database;

  DuaLocalDataSource({
    required this.database,
  });

  Future<List<DuaModel>> getAllDuas() async {
    final db = await database.database;

    final result = await db.query(
      AppConstants.duasTable,
      orderBy: 'sort_order ASC',
    );

    return result
        .map(
          (map) => DuaModel.fromMap(map),
    )
        .toList();
  }

  Future<int> insertDua(DuaModel dua) async {
    final db = await database.database;

    return db.insert(
      AppConstants.duasTable,
      dua.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDua(DuaModel dua) async {
    final db = await database.database;

    if (dua.id == null) {
      throw Exception('Cannot update a dua without an id.');
    }

    await db.update(
      AppConstants.duasTable,
      dua.toMap(),
      where: 'id = ?',
      whereArgs: [dua.id],
    );
  }

  Future<void> deleteDua(int id) async {
    final db = await database.database;

    await db.delete(
      AppConstants.duasTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateSortOrder(
      int id,
      int sortOrder,
      ) async {
    final db = await database.database;

    await db.update(
      AppConstants.duasTable,
      {
        'sort_order': sortOrder,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> hasDuas() async {
    final db = await database.database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM ${AppConstants.duasTable}
      ''',
    );

    final count = result.first['count'] as int;

    return count > 0;
  }

  Future<void> updateAllSortOrders(
      List<DuaModel> duas,
      ) async {
    final db = await database.database;

    await db.transaction((txn) async {
      for (int i = 0; i < duas.length; i++) {
        await txn.update(
          AppConstants.duasTable,
          {
            'sort_order': i,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [duas[i].id],
        );
      }
    });
  }
}