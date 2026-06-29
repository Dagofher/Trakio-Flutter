import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/presentation/crud_action_state.dart';
import '../core/utils/validators.dart';
import '../desings/colors.dart';
import '../features/approval_rules/presentation/providers/approval_rules_providers.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../features/budgets/domain/entities/budget_entity.dart';
import '../features/budgets/presentation/providers/budgets_providers.dart';
import '../features/categories/presentation/providers/categories_providers.dart';
import '../features/expenses/data/services/location_service.dart';
import '../features/expenses/domain/entities/expense_entity.dart';
import '../features/expenses/presentation/providers/expenses_providers.dart';

class QuickExpensePage extends ConsumerStatefulWidget {
  const QuickExpensePage({super.key});

  @override
  ConsumerState<QuickExpensePage> createState() => _QuickExpensePageState();
}

enum _Phase { capturing, processing, confirm, noPhoto }

class _QuickExpensePageState extends ConsumerState<QuickExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  _Phase _phase = _Phase.capturing;
  String? _photoPath;
  LocationResult? _location;
  String? _budgetId;
  String? _categoryId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCapture());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _startCapture() async {
    final path = await ref.read(receiptImageServiceProvider).pickFromCamera();
    if (!mounted) return;
    if (path == null) {
      setState(() => _phase = _Phase.noPhoto);
      return;
    }
    setState(() {
      _photoPath = path;
      _phase = _Phase.processing;
    });

    // OCR y GPS en paralelo.
    final results = await Future.wait([
      ref.read(receiptOcrServiceProvider).scan(path),
      ref.read(locationServiceProvider).getCurrentLocation(),
    ]);
    if (!mounted) return;

    final ocr = results[0] as dynamic; // OcrResult
    _location = results[1] as LocationResult?;
    if (ocr.amount != null) {
      _amountController.text = (ocr.amount as double).toStringAsFixed(2);
    }
    if (ocr.merchant != null) {
      _descriptionController.text = ocr.merchant as String;
    }
    setState(() => _phase = _Phase.confirm);
  }

  double _availableFor(String budgetId, List<BudgetEntity> budgets) {
    final budget = budgets.where((b) => b.id == budgetId).firstOrNull;
    if (budget == null) return 0;
    final consumed = ref.read(budgetConsumptionProvider(budgetId));
    return (budget.amount - consumed).clamp(0.0, double.infinity);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_budgetId == null) return _toast('Selecciona un presupuesto', err: true);
    if (_categoryId == null) return _toast('Selecciona una categoría', err: true);

    final amount = double.parse(_amountController.text.trim());
    final budgets = ref.read(budgetsStreamProvider).valueOrNull ?? const [];
    final available = _availableFor(_budgetId!, budgets);
    if (amount > available) {
      return _toast(
        'El monto supera el disponible (\$${available.toStringAsFixed(2)})',
        err: true,
      );
    }

    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;
    final user = auth.user;

    // Aplicar reglas de aprobación.
    final rules = ref.read(approvalRulesStreamProvider).valueOrNull ?? const [];
    final resolution = ref.read(approvalRuleEngineProvider).resolve(
          rules: rules,
          amount: amount,
          categoryId: _categoryId!,
        );
    final status =
        resolution.autoApprove ? ExpenseStatus.approved : ExpenseStatus.pending;

    final expense = ExpenseEntity(
      id: '',
      companyId: user.companyId ?? '',
      userId: user.uid,
      budgetId: _budgetId!,
      categoryId: _categoryId!,
      amount: amount,
      description: _descriptionController.text.trim(),
      latitude: _location?.latitude,
      longitude: _location?.longitude,
      status: status,
      reviewedBy: resolution.autoApprove ? 'system' : null,
      createdAt: DateTime.now(),
    );
    await ref
        .read(expenseActionProvider.notifier)
        .create(expense, photoPath: _photoPath);
  }

  void _toast(String msg, {bool err = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: err ? AppColors.errorColor : AppColors.accentColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(expenseActionProvider) is CrudLoading;

    ref.listen<CrudActionState>(expenseActionProvider, (_, next) {
      if (next is CrudSuccess) {
        _toast(next.message);
        ref.read(expenseActionProvider.notifier).reset();
        if (context.mounted) context.pop();
      } else if (next is CrudError) {
        _toast(next.message, err: true);
        ref.read(expenseActionProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gasto rápido'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: switch (_phase) {
        _Phase.capturing => const _Centered(text: 'Abriendo la cámara...'),
        _Phase.processing => const _Centered(
            text: 'Escaneando la factura...', showSpinner: true),
        _Phase.noPhoto => _NoPhoto(onRetry: _startCapture),
        _Phase.confirm => _buildConfirm(isLoading),
      },
    );
  }

  Widget _buildConfirm(bool isLoading) {
    final budgets = (ref.watch(budgetsStreamProvider).valueOrNull ?? const [])
        .where((b) => b.type == BudgetType.operational)
        .toList();
    final allCategories =
        ref.watch(categoriesStreamProvider).valueOrNull ?? const [];
    final selectedBudget = budgets.where((b) => b.id == _budgetId).firstOrNull;
    final categories = (selectedBudget == null ||
            selectedBudget.allowedCategoryIds.isEmpty)
        ? allCategories
        : allCategories
            .where((c) => selectedBudget.allowedCategoryIds.contains(c.id))
            .toList();

    return AbsorbPointer(
      absorbing: isLoading,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_photoPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_photoPath!),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 8),
              _DetectedBanner(
                hasAmount: _amountController.text.isNotEmpty,
                hasLocation: _location != null,
              ),
              const SizedBox(height: 16),
              const _Label('Monto detectado'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: _dec('0.00').copyWith(
                  prefixText: '\$ ',
                  prefixStyle: const TextStyle(color: Colors.white),
                ),
                validator: Validators.requiredAmount,
              ),
              const SizedBox(height: 16),
              const _Label('Descripción'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('Comercio o concepto'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresa una descripción'
                    : null,
              ),
              const SizedBox(height: 16),
              const _Label('Presupuesto'),
              const SizedBox(height: 8),
              _Dropdown(
                hint: 'Selecciona un presupuesto',
                value: budgets.any((b) => b.id == _budgetId) ? _budgetId : null,
                items: budgets
                    .map((b) =>
                        DropdownMenuItem(value: b.id, child: Text(b.name)))
                    .toList(),
                onChanged: (v) => setState(() {
                  _budgetId = v;
                  _categoryId = null;
                }),
              ),
              const SizedBox(height: 16),
              const _Label('Categoría'),
              const SizedBox(height: 8),
              _Dropdown(
                hint: 'Selecciona una categoría',
                value:
                    categories.any((c) => c.id == _categoryId) ? _categoryId : null,
                items: categories
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Guardar gasto',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _startCapture,
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.accentColor, size: 18),
                label: const Text('Volver a escanear',
                    style: TextStyle(color: AppColors.accentColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(String hint) {
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
}

// ── Sub-widgets ─────────────────────────────────────────────

class _Centered extends StatelessWidget {
  final String text;
  final bool showSpinner;
  const _Centered({required this.text, this.showSpinner = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner) ...[
            const CircularProgressIndicator(color: AppColors.accentColor),
            const SizedBox(height: 16),
          ],
          Text(text, style: const TextStyle(color: AppColors.textColor)),
        ],
      ),
    );
  }
}

class _NoPhoto extends StatelessWidget {
  final VoidCallback onRetry;
  const _NoPhoto({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.no_photography_rounded,
                size: 56, color: AppColors.textColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('No se tomó ninguna foto',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.camera_alt_rounded, color: Colors.white),
              label: const Text('Tomar foto',
                  style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectedBanner extends StatelessWidget {
  final bool hasAmount;
  final bool hasLocation;
  const _DetectedBanner({required this.hasAmount, required this.hasLocation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 18, color: AppColors.accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasAmount
                  ? 'Monto detectado automáticamente. Verifícalo antes de guardar.'
                  : 'No se detectó el monto. Ingrésalo manualmente.',
              style: const TextStyle(
                  color: AppColors.textColor, fontSize: 12.5, height: 1.3),
            ),
          ),
          Icon(
            hasLocation ? Icons.location_on : Icons.location_off,
            size: 18,
            color: hasLocation
                ? const Color(0xFF4CAF50)
                : AppColors.textColor.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: AppColors.textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600));
  }
}

class _Dropdown extends StatelessWidget {
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _Dropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceColor,
          hint: Text(hint,
              style:
                  TextStyle(color: AppColors.textColor.withValues(alpha: 0.4))),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textColor),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
