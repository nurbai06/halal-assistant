import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/status_style.dart';
import '../../ingredient_checker/models/ingredient_info.dart';
import '../bloc/ingredients_bloc.dart';
import 'ingredient_details_screen.dart';

/// The backend's ingredient knowledge database, searchable.
class IngredientsScreen extends StatelessWidget {
  const IngredientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingredient dictionary')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (query) => context.read<IngredientsBloc>().add(
                IngredientsSearchChanged(query),
              ),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search by name or E-number',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<IngredientsBloc, IngredientsState>(
              builder: (context, state) {
                if (state.all.isEmpty) {
                  return switch (state.status) {
                    IngredientsStatus.failure => ErrorView(
                      message: state.error ?? 'Could not load the dictionary.',
                      onRetry: () => context.read<IngredientsBloc>().add(
                        const IngredientsRequested(),
                      ),
                    ),
                    IngredientsStatus.success => const EmptyView(
                      icon: Icons.menu_book_outlined,
                      title: 'The dictionary is empty',
                      message: 'The server returned no ingredients.',
                    ),
                    _ => const Center(child: CircularProgressIndicator()),
                  };
                }

                final visible = state.visible;
                if (visible.isEmpty) {
                  return EmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'No match',
                    message:
                        'Nothing in the dictionary matches "${state.query}".',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _IngredientTile(ingredient: visible[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  const _IngredientTile({required this.ingredient});

  final IngredientInfo ingredient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = ingredient.classification;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            Navigator.of(context)
                .push(IngredientDetailsScreen.route(ingredient.code)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  ingredient.eNumber ?? '—',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    StatusChip(
                      label: status.label,
                      color: status.color,
                      icon: status.icon,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
