import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_client.dart';
import '../../ingredient_checker/models/analysis_result.dart';
import '../../ingredient_checker/repository/halal_repository.dart';

part 'scanner_event.dart';
part 'scanner_state.dart';

class ScannerBloc extends Bloc<ScannerEvent, ScannerState> {
  ScannerBloc(this._repository) : super(const ScannerState()) {
    on<BarcodeScanned>(_onBarcodeScanned);
    on<ScannerReset>((event, emit) => emit(const ScannerState()));
  }

  final HalalRepository _repository;

  static final _productBarcode = RegExp(r'^\d{6,14}$');

  Future<void> _onBarcodeScanned(
    BarcodeScanned event,
    Emitter<ScannerState> emit,
  ) async {
    // The camera reports the same code many times a second; only the first
    // one starts a lookup.
    if (state.status != ScannerStatus.scanning) return;

    final barcode = event.barcode.trim();
    if (!_productBarcode.hasMatch(barcode)) {
      emit(
        ScannerState(
          status: ScannerStatus.failure,
          barcode: barcode,
          error: 'That is not a product barcode. A barcode is 6 to 14 digits.',
        ),
      );
      return;
    }

    emit(ScannerState(status: ScannerStatus.loading, barcode: barcode));
    try {
      final result = await _repository.lookupBarcode(barcode);
      emit(
        result == null
            ? ScannerState(status: ScannerStatus.notFound, barcode: barcode)
            : ScannerState(
                status: ScannerStatus.success,
                barcode: barcode,
                result: result,
              ),
      );
    } on ApiException catch (error) {
      emit(
        ScannerState(
          status: ScannerStatus.failure,
          barcode: barcode,
          error: error.message,
        ),
      );
    }
  }
}
