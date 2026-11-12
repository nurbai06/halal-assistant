import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/check_tile.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_style.dart';
import '../../ingredient_checker/models/analysis_result.dart';
import '../../ingredient_checker/models/dashboard_data.dart';
import '../../product_details/screens/result_screen.dart';
import '../../scanner/screens/scanner_screen.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/navigation_cubit.dart';
import '../widgets/action_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final bloc = context.read<DashboardBloc>()
              ..add(const DashboardRequested());
            await bloc.stream.firstWhere(
              (state) => state.status != DashboardStatus.loading,
            );
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const _Header(),
              const SizedBox(height: 16),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ActionCard(
                        filled: true,
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Scan Barcode',
                        subtitle: 'Point the camera at a product',
                        onTap: () =>
                            Navigator.of(context).push(ScannerScreen.route()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ActionCard(
                        icon: Icons.edit_note_rounded,
                        title: 'Check Ingredients Manually',
                        subtitle: 'Type the list from the label',
                        onTap: () => context.read<NavigationCubit>().select(
                          AppTab.check,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              BlocBuilder<DashboardBloc, DashboardState>(
                builder: (context, state) => _DashboardSection(state: state),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('What the results mean'),
              const SizedBox(height: 12),
              const _Legend(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.seed, AppTheme.brandDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.eco_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text(
                'Halal Assistant',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Assalamu alaikum!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Understand what is in your food before you buy it.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

/// Statistics and recent checks, from GET /api/dashboard.
class _DashboardSection extends StatelessWidget {
  const _DashboardSection({required this.state});

  final DashboardState state;

  @override
  Widget build(BuildContext context) {
    final data = state.data;

    if (data == null) {
      return SizedBox(
        height: 220,
        child: state.status == DashboardStatus.failure
            ? ErrorView(
                message: state.error ?? 'Could not load the dashboard.',
                onRetry: () => context.read<DashboardBloc>().add(
                  const DashboardRequested(),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Stats(data: data),
        const SizedBox(height: 24),
        const _SectionTitle('Recently checked'),
        const SizedBox(height: 12),
        if (data.recentChecks.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: EmptyView(
                icon: Icons.inventory_2_outlined,
                title: 'No products checked yet',
                message: 'Scan a barcode or enter ingredients to get started.',
              ),
            ),
          )
        else
          for (final result in data.recentChecks) ...[
            CheckTile(
              result: result,
              onTap: () =>
                  Navigator.of(context).push(ResultScreen.route(result)),
            ),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${data.totalChecks}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    data.totalChecks == 1
                        ? 'product checked'
                        : 'products checked',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final status in AnalysisStatus.values)
                  Expanded(
                    child: Column(
                      children: [
                        Icon(status.icon, color: status.color, size: 22),
                        const SizedBox(height: 4),
                        Text(
                          '${data.statusCounts[status] ?? 0}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Short explanation of the four possible results.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            for (final status in AnalysisStatus.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(status.icon, color: status.color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: status.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status.meaning,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}
