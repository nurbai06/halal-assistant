part of 'scanner_bloc.dart';

sealed class ScannerEvent extends Equatable {
  const ScannerEvent();

  @override
  List<Object?> get props => [];
}

/// The camera read a barcode, or the user typed one in.
final class BarcodeScanned extends ScannerEvent {
  const BarcodeScanned(this.barcode);

  final String barcode;

  @override
  List<Object?> get props => [barcode];
}

/// Go back to scanning after a result, a miss or an error.
final class ScannerReset extends ScannerEvent {
  const ScannerReset();
}
