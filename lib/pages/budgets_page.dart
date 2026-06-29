import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/presentation/crud_action_state.dart';
import '../desings/colors.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../features/budgets/domain/entities/budget_entity.dart';
import '../features/budgets/presentation/providers/budgets_providers.dart';
import '../widgets/budget_card.dart';
import '../widgets/budget_form_sheet.dart';
import '../widgets/budget_payments_sheet.dart';

class BudgetsPage extends ConsumerWidget {
  const BudgetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final canManage = user?.isAdmin ?? false;
    final companyId = user?.companyId;
    final budgetsAsync = ref.watch(budgetsStreamProvider);

    ref.listen<CrudActionState>(budgetActionProvider, (_, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next is CrudSuccess) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.accentColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(budgetActionProvider.notifier).reset();
      } else if (next is CrudError) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(budgetActionProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(canManage ? 'Presupuestos' : 'Mi presupuesto disponible'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: (canManage && companyId != null)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accentColor,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Nuevo',
                  style: TextStyle(color: Colors.white)),
              onPressed: () =>
                  showBudgetFormSheet(context, companyId: companyId),
            )
          : null,
      body: budgetsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentColor),
        ),
        error: (err, stack) => Center(
          child: Text(
            'No se pudieron cargar los presupuestos.',
            style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.7)),
          ),
        ),
        data: (budgets) {
          if (budgets.isEmpty) {
            return _EmptyState(canManage: canManage);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: budgets.length,
            itemBuilder: (context, i) {
              final budget = budgets[i];
              return BudgetCard(
                budget: budget,
                canManage: canManage,
                onEdit: () => showBudgetFormSheet(
                  context,
                  companyId: budget.companyId,
                  existing: budget,
                ),
                onDelete: () => _confirmDelete(context, ref, budget),
                onPayments: () => showBudgetPaymentsSheet(
                  context,
                  budget: budget,
                  canManage: canManage,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    BudgetEntity budget,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: const Text('Eliminar presupuesto',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Seguro que deseas eliminar "${budget.name}"?',
          style: const TextStyle(color: AppColors.textColor),
        ),
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
      await ref.read(budgetActionProvider.notifier).delete(budget.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final bool canManage;
  const _EmptyState({required this.canManage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: AppColors.textColor.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'Aún no hay presupuestos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              canManage
                  ? 'Crea el primero con el botón "Nuevo".'
                  : 'El administrador aún no ha creado presupuestos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
