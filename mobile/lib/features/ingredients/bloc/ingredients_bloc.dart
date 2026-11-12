import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../ingredient_checker/models/ingredient_info.dart';
import '../../ingredient_checker/repository/halal_repository.dart';

part 'ingredients_event.dart';
part 'ingredients_state.dart';

class IngredientsBloc extends Bloc<IngredientsEvent, IngredientsState> {
  IngredientsBloc(this._repository) : super(const IngredientsState()) {
    on<IngredientsRequested>(_onRequested);
    on<IngredientsSearchChanged>(
      (event, emit) => emit(state.copyWith(query: event.query)),
    );
  }

  final HalalRepository _repository;

  Future<void> _onRequested(
    IngredientsRequested event,
    Emitter<IngredientsState> emit,
  ) async {
    emit(state.copyWith(status: IngredientsStatus.loading, error: () => null));
    try {
      final ingredients = await _repository.getIngredients();
      emit(state.copyWith(status: IngredientsStatus.success, all: ingredients));
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: IngredientsStatus.failure,
          error: () => error.message,
        ),
      );
    }
  }
}
