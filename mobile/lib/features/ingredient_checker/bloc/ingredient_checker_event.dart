part of 'ingredient_checker_bloc.dart';

sealed class IngredientCheckerEvent extends Equatable {
  const IngredientCheckerEvent();

  @override
  List<Object?> get props => [];
}

/// Send a manually entered product to the backend for analysis.
final class IngredientsSubmitted extends IngredientCheckerEvent {
  const IngredientsSubmitted({
    required this.productName,
    required this.ingredients,
  });

  final String productName;
  final String ingredients;

  @override
  List<Object?> get props => [productName, ingredients];
}

/// Forget the last result so the form can be used again.
final class IngredientCheckerReset extends IngredientCheckerEvent {
  const IngredientCheckerReset();
}
