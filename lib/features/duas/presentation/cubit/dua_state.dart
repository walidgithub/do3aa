import 'package:equatable/equatable.dart';

import '../../domain/entities/dua.dart';

abstract class DuaState extends Equatable {
  const DuaState();

  @override
  List<Object?> get props => [];
}

class DuaInitial extends DuaState {}

class DuaLoading extends DuaState {}

class DuaLoaded extends DuaState {
  final List<Dua> duas;

  const DuaLoaded(this.duas);

  @override
  List<Object?> get props => [duas];
}

class DuaError extends DuaState {
  final String message;

  const DuaError(this.message);

  @override
  List<Object?> get props => [message];
}

