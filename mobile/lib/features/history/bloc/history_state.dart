part of 'history_bloc.dart';

enum HistoryStatus { initial, loading, success, failure }

final class HistoryState extends Equatable {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.items = const [],
    this.error,
    this.actionError,
  });

  final HistoryStatus status;
  final List<AnalysisResult> items;

  /// Why the list could not be loaded.
  final String? error;

  /// Why the last delete failed; the list itself is still valid.
  final String? actionError;

  HistoryState copyWith({
    HistoryStatus? status,
    List<AnalysisResult>? items,
    String? Function()? error,
    String? Function()? actionError,
  }) => HistoryState(
    status: status ?? this.status,
    items: items ?? this.items,
    error: error != null ? error() : this.error,
    actionError: actionError != null ? actionError() : this.actionError,
  );

  @override
  List<Object?> get props => [status, items, error, actionError];
}
