import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../models/analysis_result.dart';
import '../repository/halal_repository.dart';

part 'ingredient_checker_event.dart';
part 'ingredient_checker_state.dart';

class IngredientCheckerBloc
    extends Bloc<IngredientCheckerEvent, IngredientCheckerState> {
  IngredientCheckerBloc(this._repository)
    : super(const IngredientCheckerState()) {
    on<IngredientsSubmitted>(_onSubmitted);
    on<IngredientCheckerReset>(
      (event, emit) => emit(const IngredientCheckerState()),
    );
  }

  final HalalRepository _repository;

  Future<void> _onSubmitted(
    IngredientsSubmitted event,
    Emitter<IngredientCheckerState> emit,
  ) async {
    if (state.isLoading) return;
    emit(const IngredientCheckerState(status: CheckerStatus.loading));
    try {
      // The classification happens on the server, never in the app.
      final result = await _repository.analyzeIngredients(
        productName: event.productName,
        ingredients: event.ingredients,
      );
      emit(
        IngredientCheckerState(status: CheckerStatus.success, result: result),
      );
    } on ApiException catch (error) {
      emit(
        IngredientCheckerState(
          status: CheckerStatus.failure,
          error: error.message,
        ),
      );
    }
  }
}
