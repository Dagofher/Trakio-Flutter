import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/validators.dart';
import '../desings/colors.dart';
import '../features/approval_rules/domain/entities/approval_rule.dart';
import '../features/approval_rules/presentation/providers/approval_rules_providers.dart';
import '../features/categories/presentation/providers/categories_providers.dart';

Future<void> showApprovalRuleFormSheet(
  BuildContext context, {
  required String companyId,
  ApprovalRule? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _RuleForm(companyId: companyId, existing: existing),
    ),
  );
}

class _RuleForm extends ConsumerStatefulWidget {
  final String companyId;
  final ApprovalRule? existing;

  const _RuleForm({required this.companyId, this.existing});

  @override
  ConsumerState<_RuleForm> createState() => _RuleFormState();
}

class _RuleFormState extends ConsumerState<_RuleForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _minController;
  late final TextEditingController _maxController;
  late ApprovalOutcome _outcome;
  String? _categoryId; // null = cualquier categoría

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existing;
    _minController =
        TextEditingController(text: r != null ? r.minAmount.toStringAsFixed(2) : '');
    _maxController = TextEditingController(
        text: r?.maxAmount != null ? r!.maxAmount!.toStringAsFixed(2) : '');
    _outcome = r?.outcome ?? ApprovalOutcome.requireAdmin;
    _categoryId = r?.categoryId;
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final min = double.parse(_minController.text.trim());
    final maxText = _maxController.text.trim();
    final max = maxText.isEmpty ? null : double.parse(maxText);
    if (max != null && max < min) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('El máximo no puede ser menor que el mínimo'),
        backgroundColor: AppColors.errorColor,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final rule = ApprovalRule(
      id: widget.existing?.id ?? '',
      companyId: widget.companyId,
      minAmount: min,
      maxAmount: max,
      categoryId: _categoryId,
      outcome: _outcome,
    );
    await ref.read(approvalRuleActionProvider.notifier).save(rule);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? const [];

    return SafeArea(
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
              Text(_isEditing ? 'Editar regla' : 'Nueva regla',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('Monto mínimo'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _minController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          decoration: _dec('0.00'),
                          validator: Validators.requiredAmount,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('Máximo (opcional)'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _maxController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          decoration: _dec('Sin tope'),
                          validator: Validators.optionalAmount,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _Label('Resultado'),
              const SizedBox(height: 10),
              ...ApprovalOutcome.values.map((o) => _OutcomeOption(
                    outcome: o,
                    selected: _outcome == o,
                    onTap: () => setState(() => _outcome = o),
                  )),
              const SizedBox(height: 16),
              const _Label('Categoría (opcional)'),
              const SizedBox(height: 8),
              _CategoryDropdown(
                categories: categories,
                selected: _categoryId,
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
                  child: Text(_isEditing ? 'Guardar cambios' : 'Crear regla',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                ),
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
      prefixText: '\$ ',
      prefixStyle: const TextStyle(color: Colors.white),
      hintStyle: TextStyle(color: AppColors.textColor.withValues(alpha: 0.4)),
      filled: true,
      fillColor: AppColors.surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: border(AppColors.borderColor),
      enabledBorder: border(AppColors.borderColor),
      focusedBorder: border(AppColors.accentColor),
      errorBorder: border(AppColors.errorColor),
      focusedErrorBorder: border(AppColors.errorColor),
      errorStyle: const TextStyle(color: AppColors.errorColor, fontSize: 11),
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

class _OutcomeOption extends StatelessWidget {
  final ApprovalOutcome outcome;
  final bool selected;
  final VoidCallback onTap;

  const _OutcomeOption({
    required this.outcome,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentColor.withValues(alpha: 0.15)
                : AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.accentColor : AppColors.borderColor,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                outcome.isAuto
                    ? Icons.bolt_rounded
                    : Icons.verified_user_rounded,
                size: 20,
                color: selected ? AppColors.accentColor : AppColors.textColor,
              ),
              const SizedBox(width: 12),
              Text(outcome.label,
                  style: TextStyle(
                      color: selected ? Colors.white : AppColors.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    size: 20, color: AppColors.accentColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final List<dynamic> categories;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value =
        categories.any((c) => c.id == selected) ? selected : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceColor,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textColor),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Cualquier categoría'),
            ),
            ...categories.map((c) => DropdownMenuItem<String?>(
                  value: c.id as String,
                  child: Text(c.name as String),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
