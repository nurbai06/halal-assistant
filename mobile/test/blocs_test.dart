import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halal_assistant/core/network/api_client.dart';
import 'package:halal_assistant/features/history/bloc/history_bloc.dart';
import 'package:halal_assistant/features/home/bloc/dashboard_bloc.dart';
import 'package:halal_assistant/features/ingredient_checker/bloc/ingredient_checker_bloc.dart';
import 'package:halal_assistant/features/ingredient_checker/models/analysis_result.dart';
import 'package:halal_assistant/features/ingredient_checker/models/dashboard_data.dart';
import 'package:halal_assistant/features/ingredient_checker/repository/halal_repository.dart';
import 'package:halal_assistant/features/scanner/bloc/scanner_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockHalalRepository extends Mock implements HalalRepository {}

AnalysisResult resultFor(String name, {int id = 1}) => AnalysisResult.fromJson({
  'id': id,
  'product_name': name,
  'source': 'manual',
  'ingredients_text': 'Sugar, E471',
  'overall_status': 'NEEDS_VERIFICATION',
  'summary': 'summary',
  'recommendation': 'recommendation',
  'ingredients': [
    {'text': 'Sugar', 'status': 'permissible', 'explanation': 'ok'},
    {
      'text': 'E471',
      'status': 'needs_verification',
      'explanation': 'origin unknown',
      'e_number': 'E471',
      'code': 'mono-diglycerides',
    },
  ],
  'certification': {
    'status': 'UNKNOWN',
    'message': 'message',
    'notice': 'notice',
  },
  'disclaimer': 'disclaimer',
  'checked_at': '2026-01-01T10:00:00Z',
});

void main() {
  const offline = ApiException('offline');
  late MockHalalRepository repository;

  setUp(() => repository = MockHalalRepository());

  test('AnalysisResult parses the backend response', () {
    final result = resultFor('Biscuits');
    expect(result.status, AnalysisStatus.needsVerification);
    expect(result.certification.status, CertificationStatus.unknown);
    expect(result.ingredients.last.status, FindingStatus.needsVerification);
    expect(result.ingredients.last.code, 'mono-diglycerides');
  });

  group('IngredientCheckerBloc', () {
    final biscuits = resultFor('Biscuits');

    blocTest<IngredientCheckerBloc, IngredientCheckerState>(
      'emits loading then the result the backend returned',
      setUp: () => when(
        () => repository.analyzeIngredients(
          productName: 'Biscuits',
          ingredients: 'Sugar, E471',
        ),
      ).thenAnswer((_) async => biscuits),
      build: () => IngredientCheckerBloc(repository),
      act: (bloc) => bloc.add(
        const IngredientsSubmitted(
          productName: 'Biscuits',
          ingredients: 'Sugar, E471',
        ),
      ),
      expect: () => [
        const IngredientCheckerState(status: CheckerStatus.loading),
        IngredientCheckerState(status: CheckerStatus.success, result: biscuits),
      ],
    );

    blocTest<IngredientCheckerBloc, IngredientCheckerState>(
      'emits failure with the error message when the backend is unreachable',
      setUp: () => when(
        () => repository.analyzeIngredients(
          productName: any(named: 'productName'),
          ingredients: any(named: 'ingredients'),
        ),
      ).thenThrow(offline),
      build: () => IngredientCheckerBloc(repository),
      act: (bloc) => bloc.add(
        const IngredientsSubmitted(productName: '', ingredients: 'Sugar'),
      ),
      expect: () => [
        const IngredientCheckerState(status: CheckerStatus.loading),
        const IngredientCheckerState(
          status: CheckerStatus.failure,
          error: 'offline',
        ),
      ],
    );
  });

  group('ScannerBloc', () {
    final nutella = resultFor('Hazelnut spread');

    blocTest<ScannerBloc, ScannerState>(
      'looks the barcode up and emits the product',
      setUp: () =>
          when(() => repository.lookupBarcode('3017620422003'))
              .thenAnswer((_) async => nutella),
      build: () => ScannerBloc(repository),
      act: (bloc) => bloc.add(const BarcodeScanned('3017620422003')),
      expect: () => [
        const ScannerState(
          status: ScannerStatus.loading,
          barcode: '3017620422003',
        ),
        ScannerState(
          status: ScannerStatus.success,
          barcode: '3017620422003',
          result: nutella,
        ),
      ],
    );

    blocTest<ScannerBloc, ScannerState>(
      'emits notFound when the product is unknown',
      setUp: () =>
          when(() => repository.lookupBarcode('00000000'))
              .thenAnswer((_) async => null),
      build: () => ScannerBloc(repository),
      act: (bloc) => bloc.add(const BarcodeScanned('00000000')),
      expect: () => [
        const ScannerState(status: ScannerStatus.loading, barcode: '00000000'),
        const ScannerState(status: ScannerStatus.notFound, barcode: '00000000'),
      ],
    );

    blocTest<ScannerBloc, ScannerState>(
      'ignores repeated detections while a lookup is running',
      setUp: () =>
          when(() => repository.lookupBarcode('3017620422003'))
              .thenAnswer((_) async => nutella),
      build: () => ScannerBloc(repository),
      act: (bloc) => bloc
        ..add(const BarcodeScanned('3017620422003'))
        ..add(const BarcodeScanned('3017620422003'))
        ..add(const BarcodeScanned('3017620422003')),
      verify: (_) =>
          verify(() => repository.lookupBarcode('3017620422003')).called(1),
    );

    blocTest<ScannerBloc, ScannerState>(
      'rejects codes that are not product barcodes without calling the backend',
      build: () => ScannerBloc(repository),
      act: (bloc) => bloc.add(const BarcodeScanned('https://example.com')),
      expect: () => [
        isA<ScannerState>().having(
          (s) => s.status,
          'status',
          ScannerStatus.failure,
        ),
      ],
      verify: (_) => verifyNever(() => repository.lookupBarcode(any())),
    );

    blocTest<ScannerBloc, ScannerState>(
      'emits failure on a network error and can be reset',
      setUp: () =>
          when(() => repository.lookupBarcode('12345678')).thenThrow(offline),
      build: () => ScannerBloc(repository),
      act: (bloc) => bloc
        ..add(const BarcodeScanned('12345678'))
        ..add(const ScannerReset()),
      expect: () => [
        const ScannerState(status: ScannerStatus.loading, barcode: '12345678'),
        const ScannerState(
          status: ScannerStatus.failure,
          barcode: '12345678',
          error: 'offline',
        ),
        const ScannerState(),
      ],
    );
  });

  group('HistoryBloc', () {
    final first = resultFor('First', id: 1);
    final second = resultFor('Second', id: 2);
    final loaded = HistoryState(
      status: HistoryStatus.success,
      items: [second, first],
    );

    blocTest<HistoryBloc, HistoryState>(
      'loads the history from the backend',
      setUp: () =>
          when(repository.getHistory).thenAnswer((_) async => [second, first]),
      build: () => HistoryBloc(repository),
      act: (bloc) => bloc.add(const HistoryRequested()),
      expect: () => [const HistoryState(status: HistoryStatus.loading), loaded],
    );

    blocTest<HistoryBloc, HistoryState>(
      'deletes a record on the backend',
      setUp: () =>
          when(() => repository.deleteHistoryItem(2)).thenAnswer((_) async {}),
      build: () => HistoryBloc(repository),
      seed: () => loaded,
      act: (bloc) => bloc.add(HistoryItemDeleted(second)),
      expect: () => [
        loaded.copyWith(items: [first]),
      ],
      verify: (_) => verify(() => repository.deleteHistoryItem(2)).called(1),
    );

    blocTest<HistoryBloc, HistoryState>(
      'puts the record back when the delete fails',
      setUp: () =>
          when(() => repository.deleteHistoryItem(2)).thenThrow(offline),
      build: () => HistoryBloc(repository),
      seed: () => loaded,
      act: (bloc) => bloc.add(HistoryItemDeleted(second)),
      expect: () => [
        loaded.copyWith(items: [first]),
        loaded.copyWith(actionError: () => 'offline'),
      ],
    );
  });

  group('DashboardBloc', () {
    final data = DashboardData.fromJson(const {
      'total_checks': 3,
      'status_counts': {'HALAL_INDICATED': 2, 'HARAM_INDICATOR': 1},
      'ingredient_count': 30,
      'recent_checks': <Map<String, dynamic>>[],
    });

    blocTest<DashboardBloc, DashboardState>(
      'loads statistics from the backend',
      setUp: () => when(repository.getDashboard).thenAnswer((_) async => data),
      build: () => DashboardBloc(repository),
      act: (bloc) => bloc.add(const DashboardRequested()),
      expect: () => [
        const DashboardState(status: DashboardStatus.loading),
        DashboardState(status: DashboardStatus.success, data: data),
      ],
      verify: (bloc) {
        expect(bloc.state.data!.statusCounts[AnalysisStatus.halalIndicated], 2);
        expect(
          bloc.state.data!.statusCounts[AnalysisStatus.needsVerification],
          0,
        );
      },
    );
  });
}
