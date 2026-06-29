import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../desings/colors.dart';
import '../features/budgets/domain/entities/budget_entity.dart';
import '../features/budgets/presentation/providers/budgets_providers.dart';

class BudgetCard extends ConsumerWidget {
  final BudgetEntity budget;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPayments;

  const BudgetCard({
    super.key,
    required this.budget,
    this.canManage = false,
    this.onEdit,
    this.onDelete,
    this.onPayments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(budget: budget, canManage: canManage, onEdit: onEdit, onDelete: onDelete),
          const SizedBox(height: 14),
          switch (budget.type) {
            BudgetType.operational => _OperationalBody(budget: budget),
            BudgetType.acquisition =>
              _AcquisitionBody(budget: budget, canManage: canManage, onPayments: onPayments),
            BudgetType.recurring => _RecurringBody(budget: budget),
          },
        ],
      ),
    );
  }
}

// ── Encabezado común ────────────────────────────────────────

class _Header extends StatelessWidget {
  final BudgetEntity budget;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _Header({
    required this.budget,
    required this.canManage,
    this.onEdit,
    this.onDelete,
  });

  IconData _typeIcon(BudgetType t) => switch (t) {
        BudgetType.operational => Icons.account_balance_wallet_rounded,
        BudgetType.acquisition => Icons.shopping_cart_checkout_rounded,
        BudgetType.recurring => Icons.autorenew_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final scopeText = [
      budget.scope.label,
      if (budget.scopeName.isNotEmpty) budget.scopeName,
    ].join(' · ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_typeIcon(budget.type),
              color: AppColors.accentColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                budget.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _TypeBadge(type: budget.type),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      scopeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textColor.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (canManage)
          _ManageMenu(onEdit: onEdit, onDelete: onDelete),
      ],
    );
  }
}

class _ManageMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _ManageMenu({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded,
          color: AppColors.textColor.withValues(alpha: 0.8), size: 22),
      color: AppColors.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borderColor),
      ),
      onSelected: (v) {
        if (v == 'edit') onEdit?.call();
        if (v == 'delete') onDelete?.call();
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 19, color: AppColors.textColor),
              SizedBox(width: 10),
              Text('Editar', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded,
                  size: 19, color: AppColors.errorColor),
              SizedBox(width: 10),
              Text('Eliminar', style: TextStyle(color: AppColors.errorColor)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final BudgetType type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: AppColors.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type.label,
        style: const TextStyle(
          color: AppColors.accentColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Cuerpo: Operativo ───────────────────────────────────────

class _OperationalBody extends ConsumerWidget {
  final BudgetEntity budget;
  const _OperationalBody({required this.budget});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consumed = ref.watch(budgetConsumedProvider(budget));
    final amount = budget.amount;
    final progress = amount <= 0 ? 0.0 : (consumed / amount).clamp(0.0, 1.0);
    final available = (amount - consumed).clamp(0.0, double.infinity);

    return Column(
      children: [
        _ProgressBar(progress: progress, color: _colorForProgress(progress)),
        const SizedBox(height: 12),
        _StatsRow(
          leftLabel: 'Consumido',
          leftValue: consumed,
          leftColor: _colorForProgress(progress),
          rightLabel: 'Disponible',
          rightValue: available,
        ),
        const SizedBox(height: 6),
        _FootNote(
          text:
              'Total: \$${amount.toStringAsFixed(2)} · ${budget.period?.label ?? ''} · ${(progress * 100).toStringAsFixed(0)}% usado',
        ),
      ],
    );
  }
}

// ── Cuerpo: Adquisición a plazos ────────────────────────────

class _AcquisitionBody extends ConsumerWidget {
  final BudgetEntity budget;
  final bool canManage;
  final VoidCallback? onPayments;

  const _AcquisitionBody({
    required this.budget,
    required this.canManage,
    this.onPayments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paid = ref.watch(budgetPaidProvider(budget.id));
    final total = budget.amount;
    final progress = total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);
    final remaining = (total - paid).clamp(0.0, double.infinity);
    final isPaidOff = paid >= total && total > 0;
    final payments =
        ref.watch(budgetPaymentsStreamProvider(budget.id)).valueOrNull;
    final paymentCount = payments?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressBar(
          progress: progress,
          color: isPaidOff ? const Color(0xFF4CAF50) : AppColors.accentColor,
        ),
        const SizedBox(height: 12),
        _StatsRow(
          leftLabel: 'Pagado',
          leftValue: paid,
          leftColor: const Color(0xFF4CAF50),
          rightLabel: 'Restante',
          rightValue: remaining,
        ),
        const SizedBox(height: 6),
        _FootNote(
          text: [
            'Total: \$${total.toStringAsFixed(2)}',
            '${(progress * 100).toStringAsFixed(0)}% saldado',
            if (budget.installments != null)
              '$paymentCount de ${budget.installments} cuotas',
            if (budget.dueDate != null) 'Límite: ${_fmtDate(budget.dueDate!)}',
          ].join(' · '),
        ),
        if (isPaidOff)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 16, color: Color(0xFF4CAF50)),
                SizedBox(width: 6),
                Text('Liquidado',
                    style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onPayments,
            icon: const Icon(Icons.payments_outlined, size: 18),
            label: Text(canManage ? 'Pagos / Registrar pago' : 'Ver pagos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentColor,
              side: BorderSide(
                  color: AppColors.accentColor.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Cuerpo: Recurrente ──────────────────────────────────────

class _RecurringBody extends StatelessWidget {
  final BudgetEntity budget;
  const _RecurringBody({required this.budget});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStat(
            label: 'Monto ${budget.period?.label.toLowerCase() ?? ''}',
            value: '\$${budget.amount.toStringAsFixed(2)}',
          ),
        ),
        Expanded(
          child: _MiniStat(
            label: 'Próximo cobro',
            value: budget.nextChargeDate != null
                ? _fmtDate(budget.nextChargeDate!)
                : '—',
            alignEnd: true,
          ),
        ),
      ],
    );
  }
}

// ── Piezas reutilizables ────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  const _ProgressBar({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 8,
        backgroundColor: AppColors.borderColor,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final String leftLabel;
  final double leftValue;
  final Color leftColor;
  final String rightLabel;
  final double rightValue;

  const _StatsRow({
    required this.leftLabel,
    required this.leftValue,
    required this.leftColor,
    required this.rightLabel,
    required this.rightValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MiniStat(
            label: leftLabel,
            value: '\$${leftValue.toStringAsFixed(2)}',
            color: leftColor),
        _MiniStat(
            label: rightLabel,
            value: '\$${rightValue.toStringAsFixed(2)}',
            alignEnd: true),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  const _MiniStat({
    required this.label,
    required this.value,
    this.color = Colors.white,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textColor.withValues(alpha: 0.75),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FootNote extends StatelessWidget {
  final String text;
  const _FootNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textColor.withValues(alpha: 0.8),
        fontSize: 12.5,
        height: 1.3,
      ),
    );
  }
}

Color _colorForProgress(double progress) {
  if (progress >= 0.9) return AppColors.errorColor;
  if (progress >= 0.75) return const Color(0xFFFF9800);
  return const Color(0xFF4CAF50);
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
