import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../history/bloc/history_bloc.dart';
import '../../home/bloc/dashboard_bloc.dart';
import '../../home/bloc/navigation_cubit.dart';
import '../../ingredient_checker/repository/halal_repository.dart';
import '../../product_details/screens/result_screen.dart';
import '../bloc/scanner_bloc.dart';

/// Scans a product barcode with the camera and asks the backend about it.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  static Route<void> route() => MaterialPageRoute(
    builder: (context) => BlocProvider(
      create: (context) => ScannerBloc(context.read<HalalRepository>()),
      child: const ScannerScreen(),
    ),
  );

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _camera = MobileScannerController(
    // Product barcodes only; QR codes and the like are not products.
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );
  final _manualController = TextEditingController();

  @override
  void dispose() {
    _camera.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value != null && value.isNotEmpty) {
      context.read<ScannerBloc>().add(BarcodeScanned(value));
    }
  }

  void _submitManual() {
    final value = _manualController.text.trim();
    if (value.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<ScannerBloc>()
      ..add(const ScannerReset())
      ..add(BarcodeScanned(value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan barcode')),
      body: BlocConsumer<ScannerBloc, ScannerState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == ScannerStatus.success,
        listener: (context, state) {
          // The backend saved the check; refresh what depends on it.
          context.read<HistoryBloc>().add(const HistoryRequested());
          context.read<DashboardBloc>().add(const DashboardRequested());
          Navigator.of(context)
              .pushReplacement(ResultScreen.route(state.result!));
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: _camera,
                          onDetect: _onDetect,
                          // Drawn over the live preview only, so it never
                          // covers the camera error message.
                          overlayBuilder: (context, constraints) =>
                              const _AimFrame(),
                          errorBuilder: (context, error) =>
                              _CameraError(error: error),
                          placeholderBuilder: (context) => const ColoredBox(
                            color: Colors.black,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        if (state.status != ScannerStatus.scanning)
                          _StatusOverlay(state: state),
                      ],
                    ),
                  ),
                ),
              ),
              _ManualEntry(
                controller: _manualController,
                enabled: state.status != ScannerStatus.loading,
                onSubmit: _submitManual,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Shown instead of the camera when it cannot be used.
class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Camera access was denied. Allow it in the device settings, or type '
            'the barcode below.',
      MobileScannerErrorCode.unsupported =>
        'This device has no camera the scanner can use. Type the barcode '
            'below instead.',
      _ => 'The camera could not be started. Type the barcode below instead.',
    };
    return ColoredBox(
      color: const Color(0xFF12211A),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A frame that shows where to hold the barcode.
class _AimFrame extends StatelessWidget {
  const _AimFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 260,
            height: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Hold the barcode inside the frame',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Covers the camera while looking a barcode up, and afterwards when the
/// product was not found or the lookup failed.
class _StatusOverlay extends StatelessWidget {
  const _StatusOverlay({required this.state});

  final ScannerState state;

  @override
  Widget build(BuildContext context) {
    final Widget content = switch (state.status) {
      ScannerStatus.notFound => _OverlayCard(
        icon: Icons.search_off_rounded,
        title: 'Product not found',
        message:
            'Barcode ${state.barcode} is not in the Open Food Facts '
            'database. You can still check the product by typing its '
            'ingredients.',
        primaryLabel: 'Enter ingredients manually',
        onPrimary: () {
          context.read<NavigationCubit>().select(AppTab.check);
          Navigator.of(context).pop();
        },
        secondaryLabel: 'Scan another product',
        onSecondary: () =>
            context.read<ScannerBloc>().add(const ScannerReset()),
      ),
      ScannerStatus.failure => _OverlayCard(
        icon: Icons.error_outline_rounded,
        title: 'Lookup failed',
        message: state.error ?? 'Something went wrong.',
        primaryLabel: 'Try again',
        onPrimary: () => context.read<ScannerBloc>().add(const ScannerReset()),
      ),
      _ => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Looking up ${state.barcode ?? 'the product'}…',
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    };

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: content,
        ),
      ),
    );
  }
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Typing the number works when the camera is unavailable or the barcode is
/// damaged.
class _ManualEntry extends StatelessWidget {
  const _ManualEntry({
    required this.controller,
    required this.enabled,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSubmit(),
                decoration: const InputDecoration(
                  labelText: 'Or type the barcode',
                  hintText: '3017620422003',
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: enabled ? onSubmit : null,
              tooltip: 'Look up',
              iconSize: 26,
              padding: const EdgeInsets.all(14),
              icon: const Icon(Icons.search_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
