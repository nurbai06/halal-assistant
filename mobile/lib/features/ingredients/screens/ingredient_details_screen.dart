import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/status_style.dart';
import '../../ingredient_checker/models/ingredient_info.dart';
import '../../ingredient_checker/repository/halal_repository.dart';
import '../bloc/ingredient_details_bloc.dart';

/// Everything the knowledge database says about one ingredient, loaded from
/// GET /api/ingredients/{code}.
class IngredientDetailsScreen extends StatelessWidget {
  const IngredientDetailsScreen({super.key, required this.code});

  final String code;

  static Route<void> route(String code) => MaterialPageRoute(
    builder: (context) => BlocProvider(
      create: (context) =>
          IngredientDetailsBloc(context.read<HalalRepository>())
            ..add(IngredientDetailsRequested(code)),
      child: IngredientDetailsScreen(code: code),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingredient details')),
      body: BlocBuilder<IngredientDetailsBloc, IngredientDetailsState>(
        builder: (context, state) => switch (state.status) {
          IngredientDetailsStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          IngredientDetailsStatus.failure => ErrorView(
            message: state.error ?? 'Could not load this ingredient.',
            onRetry: () => context.read<IngredientDetailsBloc>().add(
              IngredientDetailsRequested(code),
            ),
          ),
          IngredientDetailsStatus.success => _Details(
            ingredient: state.ingredient!,
          ),
        },
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.ingredient});

  final IngredientInfo ingredient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ingredient.classification;
    final otherNames = ingredient.aliases
        .where((alias) => alias != ingredient.eNumber?.toLowerCase())
        .join(', ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ingredient.eNumber != null)
                  Text(
                    ingredient.eNumber!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                Text(
                  ingredient.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                StatusChip(
                  label: status.label,
                  color: status.color,
                  icon: status.icon,
                ),
                const SizedBox(height: 12),
                Text(
                  ingredient.description,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _Section(
          icon: Icons.spa_outlined,
          title: 'Possible origin',
          text: ingredient.possibleOrigin,
        ),
        _Section(
          icon: Icons.balance_rounded,
          title: 'Halal assessment',
          text: ingredient.halalAssessment,
        ),
        _Section(
          icon: Icons.label_outline_rounded,
          title: 'Why it is classified this way',
          text: ingredient.reason,
        ),
        _Section(
          icon: Icons.fact_check_outlined,
          title: 'Verification advice',
          text: ingredient.verificationAdvice,
        ),
        if (otherNames.isNotEmpty)
          _Section(
            icon: Icons.sell_outlined,
            title: 'Also listed as',
            text: otherNames,
          ),
        if (ingredient.source != null)
          _Section(
            icon: Icons.source_outlined,
            title: 'Source',
            text: ingredient.source!,
          ),
        const SizedBox(height: 8),
        Text(
          'General information only, not a religious ruling. The actual '
          'source of an ingredient can differ from product to product.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
