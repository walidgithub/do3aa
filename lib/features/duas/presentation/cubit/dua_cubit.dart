import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/dua.dart';
import '../../domain/repositories/dua_repository.dart';
import 'dua_state.dart';

class DuaCubit extends Cubit<DuaState> {
  final DuaRepository repository;

  DuaCubit({
    required this.repository,
  }) : super(DuaInitial());

  Future<void> initialize() async {
    try {
      emit(DuaLoading());

      await repository.seedDefaultDuas();

      final duas = await repository.getAllDuas();

      print('Duas count: ${duas.length}');

      emit(DuaLoaded(duas));
    } catch (e, stackTrace) {
      print('Dua Error: $e');
      print(stackTrace);

      emit(
        DuaError(
          'حدث خطأ أثناء تحميل الأدعية: $e',
        ),
      );
    }
  }

  Future<void> loadDuas() async {
    try {
      final duas = await repository.getAllDuas();

      emit(DuaLoaded(duas));
    } catch (e) {
      emit(
        DuaError(
          'حدث خطأ أثناء تحميل الأدعية',
        ),
      );
    }
  }

  Future<void> addDua({
    required String text,
  }) async {
    try {
      final currentDuas = await repository.getAllDuas();

      final now = DateTime.now();

      final dua = Dua(
        text: text,
        sortOrder: currentDuas.length,
        isDefault: false,
        createdAt: now,
        updatedAt: now,
      );

      await repository.addDua(dua);

      await loadDuas();
    } catch (e) {
      emit(
        DuaError(
          'حدث خطأ أثناء إضافة الدعاء',
        ),
      );
    }
  }

  Future<void> updateDua(Dua dua) async {
    try {
      final updatedDua = Dua(
        id: dua.id,
        text: dua.text,
        sortOrder: dua.sortOrder,
        isDefault: dua.isDefault,
        createdAt: dua.createdAt,
        updatedAt: DateTime.now(),
      );

      await repository.updateDua(updatedDua);

      await loadDuas();
    } catch (e) {
      emit(
        DuaError(
          'حدث خطأ أثناء تعديل الدعاء',
        ),
      );
    }
  }

  Future<void> deleteDua(int id) async {
    try {
      await repository.deleteDua(id);

      await _reorderAfterDelete();

      await loadDuas();
    } catch (e) {
      emit(
        DuaError(
          'حدث خطأ أثناء حذف الدعاء',
        ),
      );
    }
  }

  Future<void> reorderDuas(
      int oldIndex,
      int newIndex,
      ) async {
    try {
      final state = this.state;

      if (state is! DuaLoaded) {
        return;
      }

      final duas = List<Dua>.from(state.duas);

      if (newIndex > oldIndex) {
        newIndex--;
      }

      final dua = duas.removeAt(oldIndex);

      duas.insert(newIndex, dua);

      final reorderedDuas = <Dua>[];

      for (int i = 0; i < duas.length; i++) {
        final currentDua = duas[i];

        reorderedDuas.add(
          Dua(
            id: currentDua.id,
            text: currentDua.text,
            sortOrder: i,
            isDefault: currentDua.isDefault,
            createdAt: currentDua.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
      }

      await repository.updateAllSortOrders(
        reorderedDuas,
      );

      await loadDuas();
    } catch (e) {
      emit(
        DuaError(
          'حدث خطأ أثناء إعادة ترتيب الأدعية',
        ),
      );
    }
  }

  Future<void> _reorderAfterDelete() async {
    final duas = await repository.getAllDuas();

    for (int i = 0; i < duas.length; i++) {
      if (duas[i].sortOrder != i) {
        await repository.updateSortOrder(
          duas[i].id!,
          i,
        );
      }
    }
  }

  Future<void> saveLastReadDua(int duaId) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setInt(
      AppConstants.lastReadDuaIdKey,
      duaId,
    );
  }

  Future<int?> getLastReadDuaId() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getInt(
      AppConstants.lastReadDuaIdKey,
    );
  }

  Future<void> clearLastReadDua() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(
      AppConstants.lastReadDuaIdKey,
    );
  }
}