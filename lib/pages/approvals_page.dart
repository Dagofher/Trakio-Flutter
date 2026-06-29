import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/presentation/crud_action_state.dart';
import '../desings/colors.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../features/expenses/domain/entities/expense_entity.dart';
import '../features/expenses/presentation/providers/expenses_providers.dart';
import '../widgets/expense_review_sheet.dart';
import '../widgets/expense_tile.dart';

class ApprovalsPage extends ConsumerWidget {
  const ApprovalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingExpensesProvider);
    final loading =
        ref.watch(companyExpensesStreamProvider).isLoading;

    ref.listen<CrudActionState>(expenseReviewProvider, (_, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next is CrudSuccess) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.accentColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(expenseReviewProvider.notifier).reset();
      } else if (next is CrudError) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(expenseReviewProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprobaciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentColor))
          : pending.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: pending.length,
                  itemBuilder: (context, i) {
                    final expense = pending[i];
                    return ExpenseTile(
                      expense: expense,
                      onTap: () => _openReview(context, ref, expense),
                    );
                  },
                ),
    );
  }

  void _openReview(BuildContext context, WidgetRef ref, ExpenseEntity expense) {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;
    showExpenseReviewSheet(
      context,
      expense: expense,
      onApprove: (comment) => ref.read(expenseReviewProvider.notifier).review(
            expense: expense,
            approve: true,
            reviewerUid: auth.user.uid,
            comment: comment,
          ),
      onReject: (comment) => ref.read(expenseReviewProvider.notifier).review(
            expense: expense,
            approve: false,
            reviewerUid: auth.user.uid,
            comment: comment,
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
            Icon(Icons.task_alt_rounded,
                size: 64, color: AppColors.textColor.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('No hay gastos pendientes',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Cuando un empleado envíe un gasto que requiera revisión, aparecerá aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
