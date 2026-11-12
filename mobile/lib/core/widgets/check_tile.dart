import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/ingredient_checker/models/analysis_result.dart';
import 'status_chip.dart';
import 'status_style.dart';

/// One checked product in a list: name, date, barcode and status.
class CheckTile extends StatelessWidget {
  const CheckTile({
    super.key,
    required this.result,
    required this.onTap,
    this.onDelete,
  });

  final AnalysisResult result;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = result.status;
    final details = [
      if (result.checkedAt != null)
        DateFormat('d MMM y, HH:mm').format(result.checkedAt!),
      if (result.barcode != null) result.barcode!,
    ].join('  ·  ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  result.source == 'barcode'
                      ? Icons.qr_code_scanner_rounded
                      : Icons.edit_note_rounded,
                  color: status.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    StatusChip(
                      label: status.label,
                      color: status.color,
                      icon: status.icon,
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: theme.colorScheme.onSurfaceVariant,
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
