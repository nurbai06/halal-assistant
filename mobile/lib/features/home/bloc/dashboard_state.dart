part of 'dashboard_bloc.dart';

enum DashboardStatus { initial, loading, success, failure }

final class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.data,
    this.error,
  });

  final DashboardStatus status;

  /// The last data received; kept on screen while reloading.
  final DashboardData? data;
  final String? error;

  @override
  List<Object?> get props => [status, data, error];
}
