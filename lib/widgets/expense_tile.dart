import 'package:flutter/material.dart';
import '../desings/colors.dart';
import '../features/expenses/domain/entities/expense_entity.dart';

class ExpenseTile extends StatelessWidget {
  final ExpenseEntity expense;
  final VoidCallback? onTap;

  const ExpenseTile({super.key, required this.expense, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            _Thumb(photoUrl: expense.photoUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description.isEmpty
                        ? 'Sin descripción'
                        : expense.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ExpenseStatusChip(status: expense.status),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _fmtDate(expense.createdAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textColor.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  final String? photoUrl;
  const _Thumb({this.photoUrl});

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          photoUrl!,
          width: 46,
          height: 46,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => const _PlaceholderThumb(),
        ),
      );
    }
    return const _PlaceholderThumb();
  }
}

class _PlaceholderThumb extends StatelessWidget {
  const _PlaceholderThumb();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: AppColors.borderColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.receipt_long_rounded,
          color: AppColors.textColor.withValues(alpha: 0.5), size: 22),
    );
  }
}

class ExpenseStatusChip extends StatelessWidget {
  final ExpenseStatus status;
  const ExpenseStatusChip({super.key, required this.status});

  Color get _color => switch (status) {
        ExpenseStatus.draft => AppColors.textColor,
        ExpenseStatus.pending => const Color(0xFFFF9800),
        ExpenseStatus.approved => const Color(0xFF4CAF50),
        ExpenseStatus.rejected => AppColors.errorColor,
        ExpenseStatus.reimbursed => const Color(0xFF2196F3),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
