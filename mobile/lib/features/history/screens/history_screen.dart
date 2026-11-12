import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/check_tile.dart';
import '../../../core/widgets/state_views.dart';
import '../../ingredient_checker/models/analysis_result.dart';
import '../../product_details/screens/result_screen.dart';
import '../bloc/history_bloc.dart';

/// Previously checked products, stored by the backend in SQLite.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: BlocConsumer<HistoryBloc, HistoryState>(
        listenWhen: (previous, current) =>
            current.actionError != null &&
            previous.actionError != current.actionError,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.actionError!)));
        },
        builder: (context, state) {
          if (state.items.isEmpty) {
            switch (state.status) {
              case HistoryStatus.initial || HistoryStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case HistoryStatus.failure:
                return ErrorView(
                  message: state.error ?? 'Could not load the history.',
                  onRetry: () =>
                      context.read<HistoryBloc>().add(const HistoryRequested()),
                );
              case HistoryStatus.success:
                return const EmptyView(
                  icon: Icons.history_rounded,
                  title: 'No history yet',
                  message:
                      'Products you scan or check manually will appear here.',
                );
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<HistoryBloc>()
                ..add(const HistoryRequested());
              await bloc.stream.firstWhere(
                (s) => s.status != HistoryStatus.loading,
              );
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: state.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = state.items[index];
                return CheckTile(
                  key: ValueKey(item.id),
                  result: item,
                  onTap: () =>
                      Navigator.of(context).push(ResultScreen.route(item)),
                  onDelete: () => _confirmDelete(context, item),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AnalysisResult item) async {
    final bloc = context.read<HistoryBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this check?'),
        content: Text('"${item.productName}" will be removed from history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(HistoryItemDeleted(item));
  }
}
