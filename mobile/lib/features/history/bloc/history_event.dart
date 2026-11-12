part of 'history_bloc.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or reload) the checked products from the backend.
final class HistoryRequested extends HistoryEvent {
  const HistoryRequested();
}

final class HistoryItemDeleted extends HistoryEvent {
  const HistoryItemDeleted(this.item);

  final AnalysisResult item;

  @override
  List<Object?> get props => [item];
}
