import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../ingredient_checker/models/dashboard_data.dart';
import '../../ingredient_checker/repository/halal_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._repository) : super(const DashboardState()) {
    on<DashboardRequested>(_onRequested);
  }

  final HalalRepository _repository;

  Future<void> _onRequested(
    DashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardState(status: DashboardStatus.loading, data: state.data));
    try {
      final data = await _repository.getDashboard();
      emit(DashboardState(status: DashboardStatus.success, data: data));
    } on ApiException catch (error) {
      emit(
        DashboardState(
          status: DashboardStatus.failure,
          data: state.data,
          error: error.message,
        ),
      );
    }
  }
}
