part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or reload) statistics and recent checks from the backend.
final class DashboardRequested extends DashboardEvent {
  const DashboardRequested();
}
