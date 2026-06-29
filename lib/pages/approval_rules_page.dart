import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/presentation/crud_action_state.dart';
import '../desings/colors.dart';
import '../features/approval_rules/domain/entities/approval_rule.dart';
import '../features/approval_rules/presentation/providers/approval_rules_providers.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/categories/presentation/providers/categories_providers.dart';
import '../widgets/approval_rule_form_sheet.dart';

class ApprovalRulesPage extends ConsumerWidget {
  const ApprovalRulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyId = ref.watch(companyIdProvider);
    final rulesAsync = ref.watch(approvalRulesStreamProvider);
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? const [];

    ref.listen<CrudActionState>(approvalRuleActionProvider, (_, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next is CrudSuccess) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.accentColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(approvalRuleActionProvider.notifier).reset();
      } else if (next is CrudError) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(approvalRuleActionProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reglas de aprobación'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: companyId == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: AppColors.accentColor,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label:
                  const Text('Nueva', style: TextStyle(color: Colors.white)),
              onPressed: () =>
                  showApprovalRuleFormSheet(context, companyId: companyId),
            ),
      body: rulesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentColor),
        ),
        error: (err, stack) => Center(
          child: Text('No se pudieron cargar las reglas.',
              style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.7))),
        ),
        data: (rules) {
          if (rules.isEmpty) return const _EmptyState();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              const _InfoBanner(),
              const SizedBox(height: 12),
              ...rules.map((rule) {
                final categoryName = rule.categoryId == null
                    ? null
                    : categories
                        .where((c) => c.id == rule.categoryId)
                        .map((c) => c.name)
                        .firstOrNull;
                return _RuleTile(
                  rule: rule,
                  categoryName: categoryName,
                  onEdit: () => showApprovalRuleFormSheet(
                    context,
                    companyId: rule.companyId,
                    existing: rule,
                  ),
                  onDelete: () => _confirmDelete(context, ref, rule),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ApprovalRule rule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: const Text('Eliminar regla',
            style: TextStyle(color: Colors.white)),
        content: const Text('¿Seguro que deseas eliminar esta regla?',
            style: TextStyle(color: AppColors.textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(approvalRuleActionProvider.notifier).delete(rule.id);
    }
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentColor.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppColors.accentColor, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Al enviar un gasto se aplica la primera regla que coincida. '
              'Si ninguna coincide, va a revisión manual.',
              style: TextStyle(
                  color: AppColors.textColor, fontSize: 12.5, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleTile extends StatelessWidget {
  final ApprovalRule rule;
  final String? categoryName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RuleTile({
    required this.rule,
    required this.categoryName,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final range = rule.maxAmount == null
        ? 'Desde \$${rule.minAmount.toStringAsFixed(2)}'
        : '\$${rule.minAmount.toStringAsFixed(2)} – \$${rule.maxAmount!.toStringAsFixed(2)}';
    final color = rule.outcome.isAuto
        ? const Color(0xFF4CAF50)
        : AppColors.accentColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              rule.outcome.isAuto
                  ? Icons.bolt_rounded
                  : Icons.verified_user_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(range,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  [
                    rule.outcome.label,
                    if (categoryName != null) 'Categoría: $categoryName',
                  ].join(' · '),
                  style: TextStyle(
                      color: AppColors.textColor.withValues(alpha: 0.8),
                      fontSize: 12.5),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: AppColors.textColor,
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: AppColors.errorColor,
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rule_rounded,
                size: 64, color: AppColors.textColor.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('Aún no hay reglas',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Sin reglas, todo gasto enviado va a revisión manual.\nCrea una con el botón "Nueva".',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
