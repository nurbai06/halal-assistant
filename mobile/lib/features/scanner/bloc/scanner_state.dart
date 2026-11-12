part of 'scanner_bloc.dart';

enum ScannerStatus { scanning, loading, success, notFound, failure }

final class ScannerState extends Equatable {
  const ScannerState({
    this.status = ScannerStatus.scanning,
    this.barcode,
    this.result,
    this.error,
  });

  final ScannerStatus status;

  /// The barcode being looked up, or the last one looked up.
  final String? barcode;
  final AnalysisResult? result;
  final String? error;

  @override
  List<Object?> get props => [status, barcode, result, error];
}
