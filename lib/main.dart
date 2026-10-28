import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/database/app_database.dart';
import 'features/duas/data/datasources/dua_local_datasource.dart';
import 'features/duas/data/repositories/dua_repository_impl.dart';
import 'features/duas/presentation/cubit/dua_cubit.dart';
import 'features/duas/presentation/pages/duas_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final database = AppDatabase.instance;

    final localDataSource = DuaLocalDataSource(
      database: database,
    );

    final repository = DuaRepositoryImpl(
      localDataSource: localDataSource,
    );

    return BlocProvider(
      create: (_) => DuaCubit(
        repository: repository,
      )..initialize(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Do3aa',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
          ),
          useMaterial3: true,
        ),
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          );
        },
        home: const DuasPage(),
      ),
    );
  }
}