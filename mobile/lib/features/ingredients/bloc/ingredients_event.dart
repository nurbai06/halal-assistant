part of 'ingredients_bloc.dart';

sealed class IngredientsEvent extends Equatable {
  const IngredientsEvent();

  @override
  List<Object?> get props => [];
}

/// Load the ingredient knowledge database from the backend.
final class IngredientsRequested extends IngredientsEvent {
  const IngredientsRequested();
}

final class IngredientsSearchChanged extends IngredientsEvent {
  const IngredientsSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
