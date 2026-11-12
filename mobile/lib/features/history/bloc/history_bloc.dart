import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../ingredient_checker/models/analysis_result.dart';
import '../../ingredient_checker/repository/halal_repository.dart';

part 'history_event.dart';
part 'history_state.dart';

class HistoryBloc extends Bloc<HistoryEvent, HistoryState> {
  HistoryBloc(this._repository) : super(const HistoryState()) {
    on<HistoryRequested>(_onRequested);
    on<HistoryItemDeleted>(_onItemDeleted);
  }

  final HalalRepository _repository;

  Future<void> _onRequested(
    HistoryRequested event,
    Emitter<HistoryState> emit,
  ) async {
    emit(
      state.copyWith(
        status: HistoryStatus.loading,
        error: () => null,
        actionError: () => null,
      ),
    );
    try {
      final items = await _repository.getHistory();
      emit(state.copyWith(status: HistoryStatus.success, items: items));
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          status: HistoryStatus.failure,
          error: () => error.message,
        ),
      );
    }
  }

  /// Removes the record at once and puts it back if the server refuses.
  Future<void> _onItemDeleted(
    HistoryItemDeleted event,
    Emitter<HistoryState> emit,
  ) async {
    final id = event.item.id;
    final index = state.items.indexWhere((item) => item.id == id);
    if (id == null || index == -1) return;

    emit(
      state.copyWith(
        items: [...state.items]..removeAt(index),
        actionError: () => null,
      ),
    );
    try {
      await _repository.deleteHistoryItem(id);
    } on ApiException catch (error) {
      final restored = [...state.items];
      restored.insert(index.clamp(0, restored.length), event.item);
      emit(state.copyWith(items: restored, actionError: () => error.message));
    }
  }
}
