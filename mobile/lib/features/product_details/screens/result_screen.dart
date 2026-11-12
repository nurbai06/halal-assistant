import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/status_chip.dart';
import '../../../core/widgets/status_style.dart';
import '../../ingredient_checker/models/analysis_result.dart';
import '../../ingredients/screens/ingredient_details_screen.dart';

/// Shows one analysis exactly as the backend returned it: the overall
/// status, each ingredient's explanation, the recommended next step and,
/// separately, the certification information.
class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.result});

  final AnalysisResult result;

  static Route<void> route(AnalysisResult result) =>
      MaterialPageRoute(builder: (_) => ResultScreen(result: result));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analysis result')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          _StatusHeader(result: result),
          const SizedBox(height: 14),
          _InfoCard(
            icon: Icons.directions_rounded,
            title: 'Recommended next step',
            child: Text(result.recommendation, style: _bodyStyle(context)),
          ),
          const SizedBox(height: 14),
          _CertificationCard(certification: result.certification),
          const SizedBox(height: 22),
          _SectionTitle('Ingredients (${result.ingredients.length})'),
          const SizedBox(height: 10),
          if (result.ingredients.isEmpty)
            _InfoCard(
              icon: Icons.inventory_2_outlined,
              title: 'No ingredients available',
              child: Text(
                'No ingredient list was provided for this product.',
                style: _bodyStyle(context),
              ),
            )
          else
            for (final finding in result.ingredients) ...[
              _FindingCard(finding: finding),
              const SizedBox(height: 10),
            ],
          if (result.ingredientsText.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _SectionTitle('Ingredient list as provided'),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(result.ingredientsText, style: _bodyStyle(context)),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text(
            result.disclaimer,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

TextStyle? _bodyStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45);

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final status = result.status;
    final meta = [
      if (result.brand != null) result.brand!,
      if (result.barcode != null) 'Barcode ${result.barcode}',
    ].join('  ·  ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: status.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(status.icon, color: Colors.white, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status.label.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            result.productName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              meta,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            result.summary,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Certification is shown apart from the ingredient result on purpose: a
/// missing certificate says nothing about the ingredients.
class _CertificationCard extends StatelessWidget {
  const _CertificationCard({required this.certification});

  final CertificationInfo certification;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = certification.status;

    return _InfoCard(
      icon: Icons.workspace_premium_outlined,
      title: 'Halal certification',
      trailing: StatusChip(
        label: status.label,
        color: status.color,
        icon: status.icon,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(certification.message, style: _bodyStyle(context)),
          if (certification.notice.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      certification.notice,
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FindingCard extends StatelessWidget {
  const _FindingCard({required this.finding});

  final IngredientFinding finding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = finding.status;
    final code = finding.code;
    final knownAs = [
      if (finding.matchedName != null) finding.matchedName!,
      if (finding.eNumber != null) finding.eNumber!,
    ].join('  ·  ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: code == null
            ? null
            : () =>
                  Navigator.of(context)
                      .push(IngredientDetailsScreen.route(code)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      finding.text,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(
                    label: status.label,
                    color: status.color,
                    icon: status.icon,
                  ),
                ],
              ),
              if (knownAs.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  knownAs,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(finding.explanation, style: _bodyStyle(context)),
              if (finding.verificationAdvice != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: status.color,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        finding.verificationAdvice!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (code != null) ...[
                const SizedBox(height: 8),
                Text(
                  'View ingredient details',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

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
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
            child,
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
