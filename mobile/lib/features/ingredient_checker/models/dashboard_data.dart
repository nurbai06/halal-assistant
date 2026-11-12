import 'package:equatable/equatable.dart';

import 'analysis_result.dart';

/// Numbers and recent checks for the home screen.
class DashboardData extends Equatable {
  const DashboardData({
    required this.totalChecks,
    required this.statusCounts,
    required this.ingredientCount,
    required this.recentChecks,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final counts = json['status_counts'] as Map<String, dynamic>? ?? const {};
    return DashboardData(
      totalChecks: json['total_checks'] as int? ?? 0,
      statusCounts: {
        for (final status in AnalysisStatus.values)
          status: counts[status.apiValue] as int? ?? 0,
      },
      ingredientCount: json['ingredient_count'] as int? ?? 0,
      recentChecks: (json['recent_checks'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(AnalysisResult.fromJson)
          .toList(),
    );
  }

  final int totalChecks;
  final Map<AnalysisStatus, int> statusCounts;
  final int ingredientCount;
  final List<AnalysisResult> recentChecks;

  @override
  List<Object?> get props => [
    totalChecks,
    statusCounts,
    ingredientCount,
    recentChecks,
  ];
}
