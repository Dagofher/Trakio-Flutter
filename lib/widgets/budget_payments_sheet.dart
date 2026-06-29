import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/presentation/crud_action_state.dart';
import '../core/utils/validators.dart';
import '../desings/colors.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../features/budgets/domain/entities/budget_entity.dart';
import '../features/budgets/domain/entities/payment_entity.dart';
import '../features/budgets/presentation/providers/budgets_providers.dart';

/// Muestra el historial de pagos de un presupuesto de adquisición y permite
/// registrar nuevos pagos (si el usuario puede gestionar).
Future<void> showBudgetPaymentsSheet(
  BuildContext context, {
  required BudgetEntity budget,
  required bool canManage,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _PaymentsSheet(budget: budget, canManage: canManage),
  );
}

class _PaymentsSheet extends ConsumerWidget {
  final BudgetEntity budget;
  final bool canManage;

  const _PaymentsSheet({required this.budget, required this.canManage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(budgetPaymentsStreamProvider(budget.id));
    final paid = ref.watch(budgetPaidProvider(budget.id));
    final remaining = (budget.amount - paid).clamp(0.0, double.infinity);

    ref.listen<CrudActionState>(paymentActionProvider, (_, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next is CrudSuccess) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.accentColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(paymentActionProvider.notifier).reset();
      } else if (next is CrudError) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(paymentActionProvider.notifier).reset();
      }
    });

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: _SummaryHeader(budget: budget, paid: paid, remaining: remaining),
            ),
            const Divider(color: AppColors.borderColor, height: 1),
            Expanded(
              child: paymentsAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.accentColor),
                ),
                error: (err, stack) => Center(
                  child: Text('No se pudieron cargar los pagos.',
                      style: TextStyle(
                          color: AppColors.textColor.withValues(alpha: 0.7))),
                ),
                data: (payments) {
                  if (payments.isEmpty) {
                    return Center(
                      child: Text(
                        'Aún no hay pagos registrados.',
                        style: TextStyle(
                            color: AppColors.textColor.withValues(alpha: 0.6)),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: payments.length,
                    itemBuilder: (context, i) => _PaymentTile(
                      payment: payments[i],
                      canManage: canManage,
                      onDelete: () => ref
                          .read(paymentActionProvider.notifier)
                          .delete(budget.id, payments[i].id),
                    ),
                  );
                },
              ),
            ),
            if (canManage)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddPayment(context, ref, remaining),
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    label: const Text('Registrar pago',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showAddPayment(
    BuildContext context,
    WidgetRef ref,
    double remaining,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddPaymentForm(budget: budget, remaining: remaining),
    );
  }
}

/// Formulario para registrar un pago. StatefulWidget para que los controllers
/// se liberen de forma segura en dispose().
class _AddPaymentForm extends ConsumerStatefulWidget {
  final BudgetEntity budget;
  final double remaining;

  const _AddPaymentForm({required this.budget, required this.remaining});

  @override
  ConsumerState<_AddPaymentForm> createState() => _AddPaymentFormState();
}

class _AddPaymentFormState extends ConsumerState<_AddPaymentForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider);
    final uid = user is AuthAuthenticated ? user.user.uid : '';
    final payment = PaymentEntity(
      id: '',
      budgetId: widget.budget.id,
      amount: double.parse(_amountController.text.trim()),
      date: _date,
      note: _noteController.text.trim(),
      createdBy: uid,
    );
    await ref.read(paymentActionProvider.notifier).add(payment);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Registrar pago',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  'Restante: \$${widget.remaining.toStringAsFixed(2)}',
                  style: TextStyle(
                      color: AppColors.textColor.withValues(alpha: 0.7),
                      fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _amountController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: _fieldDecoration('Monto del pago').copyWith(
                    prefixText: '\$ ',
                    prefixStyle: const TextStyle(color: Colors.white),
                  ),
                  validator: Validators.requiredAmount,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _fieldDecoration('Nota (ej: Enganche, Cuota 1)'),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _date,
                      firstDate: DateTime(_date.year - 2),
                      lastDate: DateTime(_date.year + 1),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.borderColor, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 18, color: AppColors.textColor),
                        const SizedBox(width: 12),
                        Text(
                          '${_date.day.toString().padLeft(2, '0')}/'
                          '${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                          style:
                              const TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Guardar pago',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String hint) {
  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: 1.5),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.textColor.withValues(alpha: 0.4)),
    filled: true,
    fillColor: AppColors.surfaceColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: border(AppColors.borderColor),
    enabledBorder: border(AppColors.borderColor),
    focusedBorder: border(AppColors.accentColor),
    errorBorder: border(AppColors.errorColor),
    focusedErrorBorder: border(AppColors.errorColor),
    errorStyle: const TextStyle(color: AppColors.errorColor),
  );
}

class _SummaryHeader extends StatelessWidget {
  final BudgetEntity budget;
  final double paid;
  final double remaining;

  const _SummaryHeader({
    required this.budget,
    required this.paid,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        budget.amount <= 0 ? 0.0 : (paid / budget.amount).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          budget.name,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Costo total: \$${budget.amount.toStringAsFixed(2)}',
          style: TextStyle(
              color: AppColors.textColor.withValues(alpha: 0.7), fontSize: 13),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.borderColor,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF4CAF50)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pagado: \$${paid.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            Text('Resta: \$${remaining.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final PaymentEntity payment;
  final bool canManage;
  final VoidCallback onDelete;

  const _PaymentTile({
    required this.payment,
    required this.canManage,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final d = payment.date;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payments_rounded,
                color: Color(0xFF4CAF50), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '\$${payment.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
                    if (payment.note.isNotEmpty) payment.note,
                  ].join(' · '),
                  style: TextStyle(
                      color: AppColors.textColor.withValues(alpha: 0.6),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          if (canManage)
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
