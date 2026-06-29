import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/validators.dart';
import '../desings/colors.dart';
import '../features/budgets/domain/entities/budget_entity.dart';
import '../features/budgets/presentation/providers/budgets_providers.dart';
import '../features/categories/presentation/providers/categories_providers.dart';
import '../features/departments/domain/entities/department_entity.dart';
import '../features/departments/presentation/providers/departments_providers.dart';

/// Muestra el formulario de crear/editar presupuesto como bottom sheet.
Future<void> showBudgetFormSheet(
  BuildContext context, {
  required String companyId,
  BudgetEntity? existing,
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
      child: _BudgetFormSheet(companyId: companyId, existing: existing),
    ),
  );
}

class _BudgetFormSheet extends ConsumerStatefulWidget {
  final String companyId;
  final BudgetEntity? existing;

  const _BudgetFormSheet({required this.companyId, this.existing});

  @override
  ConsumerState<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends ConsumerState<_BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _scopeNameController;
  late final TextEditingController _installmentsController;

  late BudgetType _type;
  late BudgetScope _scope;
  String? _departmentId;
  late BudgetPeriod _period;
  late Set<String> _categoryIds;
  late Set<int> _alerts;
  DateTime? _dueDate;
  DateTime? _nextChargeDate;

  bool get _isEditing => widget.existing != null;
  bool get _isOperational => _type == BudgetType.operational;
  bool get _isAcquisition => _type == BudgetType.acquisition;
  bool get _isRecurring => _type == BudgetType.recurring;
  bool get _isDepartmentScope => _scope == BudgetScope.department;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _nameController = TextEditingController(text: b?.name ?? '');
    _amountController =
        TextEditingController(text: b != null ? b.amount.toStringAsFixed(2) : '');
    _scopeNameController = TextEditingController(text: b?.scopeName ?? '');
    _installmentsController = TextEditingController(
        text: b?.installments != null ? '${b!.installments}' : '');
    _type = b?.type ?? BudgetType.operational;
    _scope = b?.scope ?? BudgetScope.department;
    _departmentId = b?.departmentId;
    _period = b?.period ?? BudgetPeriod.monthly;
    _categoryIds = {...?b?.allowedCategoryIds};
    _alerts = {...(b?.alertThresholds ?? const [50, 75, 90])};
    _dueDate = b?.dueDate;
    _nextChargeDate = b?.nextChargeDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _scopeNameController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isDepartmentScope && _departmentId == null) return;

    final departments =
        ref.read(departmentsStreamProvider).valueOrNull ?? const [];
    final scopeName = _isDepartmentScope
        ? (departments
                .where((d) => d.id == _departmentId)
                .map((d) => d.name)
                .firstOrNull ??
            '')
        : _scopeNameController.text.trim();

    final budget = BudgetEntity(
      id: widget.existing?.id ?? '',
      companyId: widget.companyId,
      name: _nameController.text.trim(),
      type: _type,
      scope: _scope,
      scopeName: scopeName,
      departmentId: _isDepartmentScope ? _departmentId : null,
      amount: double.parse(_amountController.text.trim()),
      period: _isAcquisition ? null : _period,
      allowedCategoryIds: _isOperational ? _categoryIds.toList() : const [],
      alertThresholds:
          _isOperational ? (_alerts.toList()..sort()) : const [50, 75, 90],
      dueDate: _isAcquisition ? _dueDate : null,
      installments: _isAcquisition
          ? int.tryParse(_installmentsController.text.trim())
          : null,
      nextChargeDate: _isRecurring ? _nextChargeDate : null,
    );
    await ref.read(budgetActionProvider.notifier).save(budget);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final departments = ref.watch(departmentsStreamProvider).valueOrNull ?? [];
    final categories = ref.watch(categoriesStreamProvider).valueOrNull ?? [];

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
              Text(
                _isEditing ? 'Editar presupuesto' : 'Nuevo presupuesto',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              const _Label('Tipo de presupuesto'),
              const SizedBox(height: 10),
              _TypeSelector(
                selected: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: 20),
              const _Label('Nombre'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration(_nameHint()),
                validator: Validators.categoryName,
              ),
              const SizedBox(height: 20),
              const _Label('Alcance'),
              const SizedBox(height: 10),
              _ScopeSelector(
                selected: _scope,
                onChanged: (s) => setState(() => _scope = s),
              ),
              const SizedBox(height: 16),
              _buildScopeTarget(departments),
              const SizedBox(height: 20),
              _Label(_amountLabel()),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                style: const TextStyle(color: Colors.white),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: _decoration('Ej: 50000.00').copyWith(
                  prefixText: '\$ ',
                  prefixStyle: const TextStyle(color: Colors.white),
                ),
                validator: Validators.requiredAmount,
              ),
              const SizedBox(height: 20),
              ..._buildTypeSpecificFields(categories),
              const SizedBox(height: 28),
              _SaveButton(isEditing: _isEditing, onPressed: _onSave),
            ],
          ),
        ),
      ),
    );
  }

  // ── Campos según alcance ──────────────────────────────────

  Widget _buildScopeTarget(List<DepartmentEntity> departments) {
    if (_isDepartmentScope) {
      if (departments.isEmpty) return _NoDepartmentsNote();
      return _DepartmentDropdown(
        departments: departments,
        selected: _departmentId,
        onChanged: (v) => setState(() => _departmentId = v),
      );
    }
    return TextFormField(
      controller: _scopeNameController,
      style: const TextStyle(color: Colors.white),
      decoration: _decoration(_scopeHint()),
      validator: Validators.categoryName,
    );
  }

  // ── Campos según tipo ─────────────────────────────────────

  List<Widget> _buildTypeSpecificFields(List<dynamic> categories) {
    if (_isOperational) {
      return [
        const _Label('Periodo'),
        const SizedBox(height: 8),
        _PeriodSelector(
          selected: _period,
          onChanged: (p) => setState(() => _period = p),
        ),
        const SizedBox(height: 20),
        const _Label('Categorías permitidas'),
        const SizedBox(height: 10),
        _CategoryChips(
          categories: categories,
          selectedIds: _categoryIds,
          onToggle: (id) => setState(() {
            _categoryIds.contains(id)
                ? _categoryIds.remove(id)
                : _categoryIds.add(id);
          }),
        ),
        const SizedBox(height: 20),
        const _Label('Alertas de consumo'),
        const SizedBox(height: 10),
        _AlertChips(
          selected: _alerts,
          onToggle: (t) => setState(() {
            _alerts.contains(t) ? _alerts.remove(t) : _alerts.add(t);
          }),
        ),
      ];
    }
    if (_isAcquisition) {
      return [
        const _Label('Número de cuotas (opcional)'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _installmentsController,
          style: const TextStyle(color: Colors.white),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: _decoration('Ej: 12'),
        ),
        const SizedBox(height: 20),
        _DateField(
          label: 'Fecha límite de pago (opcional)',
          value: _dueDate,
          onPick: (d) => setState(() => _dueDate = d),
        ),
      ];
    }
    // Recurrente
    return [
      const _Label('Periodo de cobro'),
      const SizedBox(height: 8),
      _PeriodSelector(
        selected: _period,
        onChanged: (p) => setState(() => _period = p),
      ),
      const SizedBox(height: 20),
      _DateField(
        label: 'Próximo cobro (opcional)',
        value: _nextChargeDate,
        onPick: (d) => setState(() => _nextChargeDate = d),
      ),
    ];
  }

  String _nameHint() => switch (_type) {
        BudgetType.operational => 'Ej: Operaciones Q1',
        BudgetType.acquisition => 'Ej: Compra máquina CNC',
        BudgetType.recurring => 'Ej: Internet de oficina',
      };

  String _amountLabel() => switch (_type) {
        BudgetType.operational => 'Monto del pool',
        BudgetType.acquisition => 'Costo total',
        BudgetType.recurring => 'Monto por periodo',
      };

  String _scopeHint() => switch (_scope) {
        BudgetScope.team => 'Ej: Equipo de Marketing',
        BudgetScope.equipment => 'Ej: Máquina CNC-3',
        BudgetScope.area => 'Ej: Área de Producción',
        BudgetScope.project => 'Ej: Proyecto Andrómeda',
        BudgetScope.general => 'Ej: Gastos generales',
        BudgetScope.department => '',
      };

  InputDecoration _decoration(String hint) {
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textColor,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  final BudgetType selected;
  final ValueChanged<BudgetType> onChanged;

  const _TypeSelector({required this.selected, required this.onChanged});

  IconData _iconFor(BudgetType t) => switch (t) {
        BudgetType.operational => Icons.account_balance_wallet_rounded,
        BudgetType.acquisition => Icons.shopping_cart_checkout_rounded,
        BudgetType.recurring => Icons.autorenew_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: BudgetType.values.map((t) {
        final isSelected = t == selected;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => onChanged(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentColor.withValues(alpha: 0.15)
                    : AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      isSelected ? AppColors.accentColor : AppColors.borderColor,
                  width: isSelected ? 1.8 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _iconFor(t),
                    size: 20,
                    color:
                        isSelected ? AppColors.accentColor : AppColors.textColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded,
                        size: 20, color: AppColors.accentColor),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ScopeSelector extends StatelessWidget {
  final BudgetScope selected;
  final ValueChanged<BudgetScope> onChanged;

  const _ScopeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BudgetScope.values.map((s) {
        final isSelected = s == selected;
        return GestureDetector(
          onTap: () => onChanged(s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accentColor.withValues(alpha: 0.2)
                  : AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isSelected ? AppColors.accentColor : AppColors.borderColor,
              ),
            ),
            child: Text(
              s.label,
              style: TextStyle(
                color: isSelected ? AppColors.accentColor : AppColors.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;

  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? now,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 10),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 18, color: AppColors.textColor),
                const SizedBox(width: 12),
                Text(
                  value == null
                      ? 'Seleccionar fecha'
                      : '${value!.day.toString().padLeft(2, '0')}/'
                          '${value!.month.toString().padLeft(2, '0')}/${value!.year}',
                  style: TextStyle(
                    color: value == null
                        ? AppColors.textColor.withValues(alpha: 0.4)
                        : Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NoDepartmentsNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.accentColor),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Crea un departamento primero, o elige otro alcance (equipo, máquina, área...).',
              style: TextStyle(color: AppColors.textColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartmentDropdown extends StatelessWidget {
  final List<DepartmentEntity> departments;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _DepartmentDropdown({
    required this.departments,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = departments.any((d) => d.id == selected) ? selected : null;
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
          hint: Text(
            'Selecciona un departamento',
            style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.4)),
          ),
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textColor),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          items: departments
              .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final BudgetPeriod selected;
  final ValueChanged<BudgetPeriod> onChanged;

  const _PeriodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: BudgetPeriod.values.map((p) {
        final isSelected = p == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    isSelected ? AppColors.accentColor : AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      isSelected ? AppColors.accentColor : AppColors.borderColor,
                ),
              ),
              child: Text(
                p.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<dynamic> categories; // CategoryEntity
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  const _CategoryChips({
    required this.categories,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Text(
        'No hay categorías creadas todavía.',
        style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.6)),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map<Widget>((c) {
        final isSelected = selectedIds.contains(c.id);
        return GestureDetector(
          onTap: () => onToggle(c.id as String),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accentColor.withValues(alpha: 0.2)
                  : AppColors.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isSelected ? AppColors.accentColor : AppColors.borderColor,
              ),
            ),
            child: Text(
              c.name as String,
              style: TextStyle(
                color: isSelected ? AppColors.accentColor : AppColors.textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AlertChips extends StatelessWidget {
  final Set<int> selected;
  final ValueChanged<int> onToggle;

  const _AlertChips({required this.selected, required this.onToggle});

  static const _options = [50, 75, 90];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((t) {
        final isSelected = selected.contains(t);
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onToggle(t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentColor.withValues(alpha: 0.2)
                    : AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      isSelected ? AppColors.accentColor : AppColors.borderColor,
                ),
              ),
              child: Text(
                '$t%',
                style: TextStyle(
                  color:
                      isSelected ? AppColors.accentColor : AppColors.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onPressed;

  const _SaveButton({required this.isEditing, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          isEditing ? 'Guardar cambios' : 'Crear presupuesto',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
