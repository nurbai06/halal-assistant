import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../ingredient_checker/models/ingredient_info.dart';
import '../../ingredient_checker/repository/halal_repository.dart';

/// Load one knowledge-database entry by its code or E-number.
final class IngredientDetailsRequested extends Equatable {
  const IngredientDetailsRequested(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

enum IngredientDetailsStatus { loading, success, failure }

final class IngredientDetailsState extends Equatable {
  const IngredientDetailsState({
    this.status = IngredientDetailsStatus.loading,
    this.ingredient,
    this.error,
  });

  final IngredientDetailsStatus status;
  final IngredientInfo? ingredient;
  final String? error;

  @override
  List<Object?> get props => [status, ingredient, error];
}

class IngredientDetailsBloc
    extends Bloc<IngredientDetailsRequested, IngredientDetailsState> {
  IngredientDetailsBloc(this._repository)
    : super(const IngredientDetailsState()) {
    on<IngredientDetailsRequested>(_onRequested);
  }

  final HalalRepository _repository;

  Future<void> _onRequested(
    IngredientDetailsRequested event,
    Emitter<IngredientDetailsState> emit,
  ) async {
    emit(const IngredientDetailsState());
    try {
      final ingredient = await _repository.getIngredient(event.code);
      emit(
        IngredientDetailsState(
          status: IngredientDetailsStatus.success,
          ingredient: ingredient,
        ),
      );
    } on ApiException catch (error) {
      emit(
        IngredientDetailsState(
          status: IngredientDetailsStatus.failure,
          error: error.message,
        ),
      );
    }
  }
}
