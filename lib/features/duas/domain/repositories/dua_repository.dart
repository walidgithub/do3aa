import '../entities/dua.dart';

abstract class DuaRepository {
  Future<List<Dua>> getAllDuas();

  Future<int> addDua(Dua dua);

  Future<void> updateDua(Dua dua);

  Future<void> deleteDua(int id);

  Future<void> updateSortOrder(
      int id,
      int sortOrder,
      );

  Future<void> seedDefaultDuas();

  Future<void> updateAllSortOrders(
      List<Dua> duas,
      );
}