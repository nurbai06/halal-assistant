part of 'ingredient_checker_bloc.dart';

enum CheckerStatus { initial, loading, success, failure }

final class IngredientCheckerState extends Equatable {
  const IngredientCheckerState({
    this.status = CheckerStatus.initial,
    this.result,
    this.error,
  });

  final CheckerStatus status;
  final AnalysisResult? result;
  final String? error;

  bool get isLoading => status == CheckerStatus.loading;

  @override
  List<Object?> get props => [status, result, error];
}
