import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../history/bloc/history_bloc.dart';
import '../../home/bloc/dashboard_bloc.dart';
import '../../product_details/screens/result_screen.dart';
import '../bloc/ingredient_checker_bloc.dart';

/// Manual check: the user types a product name and its ingredient list, and
/// the backend analyses it.
class IngredientCheckerScreen extends StatefulWidget {
  const IngredientCheckerScreen({super.key});

  @override
  State<IngredientCheckerScreen> createState() =>
      _IngredientCheckerScreenState();
}

class _IngredientCheckerScreenState extends State<IngredientCheckerScreen> {
  static const _exampleName = 'Chocolate Biscuits';
  static const _exampleIngredients =
      'Sugar, wheat flour, vegetable oil, cocoa powder, milk powder, '
      'emulsifier E471, flavouring.';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ingredientsController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<IngredientCheckerBloc>().add(
      IngredientsSubmitted(
        productName: _nameController.text.trim(),
        ingredients: _ingredientsController.text.trim(),
      ),
    );
  }

  void _fillExample() {
    _nameController.text = _exampleName;
    _ingredientsController.text = _exampleIngredients;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check ingredients'),
        actions: [
          TextButton(onPressed: _fillExample, child: const Text('Use example')),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<IngredientCheckerBloc, IngredientCheckerState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == CheckerStatus.success,
        listener: (context, state) {
          // The backend saved the check; refresh what depends on it.
          context.read<HistoryBloc>().add(const HistoryRequested());
          context.read<DashboardBloc>().add(const DashboardRequested());
          Navigator.of(context).push(ResultScreen.route(state.result!));
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  'Copy the ingredient list from the packaging. Separate '
                  'ingredients with commas.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  enabled: !state.isLoading,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: 'Product name',
                    hintText: 'Chocolate Biscuits',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _ingredientsController,
                  enabled: !state.isLoading,
                  minLines: 5,
                  maxLines: 10,
                  maxLength: 5000,
                  decoration: const InputDecoration(
                    labelText: 'Ingredients',
                    hintText: 'Sugar, wheat flour, vegetable oil, E471…',
                    alignLabelWithHint: true,
                    counterText: '',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter at least one ingredient'
                      : null,
                ),
                const SizedBox(height: 16),
                if (state.status == CheckerStatus.failure) ...[
                  _ErrorBanner(message: state.error ?? 'Analysis failed.'),
                  const SizedBox(height: 16),
                ],
                FilledButton.icon(
                  onPressed: state.isLoading ? null : _submit,
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.fact_check_rounded),
                  label: Text(
                    state.isLoading ? 'Analysing…' : 'Analyse ingredients',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'The analysis is a preliminary, ingredient-based '
                        'assessment. It is not a religious ruling or a halal '
                        'certificate.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
