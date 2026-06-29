import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/presentation/crud_action_state.dart';
import '../desings/colors.dart';
import '../features/expenses/domain/entities/expense_entity.dart';
import '../features/expenses/presentation/providers/expenses_providers.dart';
import '../widgets/expense_detail_sheet.dart';
import '../widgets/expense_tile.dart';

class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(myExpensesStreamProvider);

    ref.listen<CrudActionState>(expenseActionProvider, (_, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next is CrudSuccess) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.accentColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(expenseActionProvider.notifier).reset();
      } else if (next is CrudError) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(expenseActionProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis gastos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.document_scanner_rounded),
            tooltip: 'Gasto rápido (escanear factura)',
            onPressed: () => context.push('/expenses/quick'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.accentColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Nuevo gasto', style: TextStyle(color: Colors.white)),
        onPressed: () => context.push('/expenses/new'),
      ),
      body: expensesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentColor),
        ),
        error: (err, stack) => Center(
          child: Text(
            'No se pudieron cargar los gastos.',
            style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.7)),
          ),
        ),
        data: (expenses) {
          if (expenses.isEmpty) return const _EmptyState();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: expenses.length,
            itemBuilder: (context, i) {
              final expense = expenses[i];
              return ExpenseTile(
                expense: expense,
                onTap: () => showExpenseDetailSheet(
                  context,
                  expense: expense,
                  onDelete: _canDelete(expense)
                      ? () => _confirmDelete(context, ref, expense)
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _canDelete(ExpenseEntity e) =>
      e.status == ExpenseStatus.draft || e.status == ExpenseStatus.pending;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ExpenseEntity expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: const Text('Eliminar gasto',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          '¿Seguro que deseas eliminar este gasto?',
          style: TextStyle(color: AppColors.textColor),
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
      await ref.read(expenseActionProvider.notifier).delete(expense.id);
    }
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
            Icon(Icons.receipt_long_outlined,
                size: 64, color: AppColors.textColor.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'Aún no has registrado gastos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea el primero con el botón "Nuevo gasto".',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
