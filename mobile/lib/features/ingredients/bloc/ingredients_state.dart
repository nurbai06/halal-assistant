part of 'ingredients_bloc.dart';

enum IngredientsStatus { initial, loading, success, failure }

final class IngredientsState extends Equatable {
  const IngredientsState({
    this.status = IngredientsStatus.initial,
    this.all = const [],
    this.query = '',
    this.error,
  });

  final IngredientsStatus status;
  final List<IngredientInfo> all;
  final String query;
  final String? error;

  /// The entries that match the search box.
  List<IngredientInfo> get visible =>
      all.where((ingredient) => ingredient.matches(query)).toList();

  IngredientsState copyWith({
    IngredientsStatus? status,
    List<IngredientInfo>? all,
    String? query,
    String? Function()? error,
  }) => IngredientsState(
    status: status ?? this.status,
    all: all ?? this.all,
    query: query ?? this.query,
    error: error != null ? error() : this.error,
  );

  @override
  List<Object?> get props => [status, all, query, error];
}
