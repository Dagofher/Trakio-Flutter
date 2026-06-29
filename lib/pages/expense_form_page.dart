import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../core/presentation/crud_action_state.dart';
import '../core/utils/validators.dart';
import '../desings/colors.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../features/budgets/domain/entities/budget_entity.dart';
import '../features/budgets/presentation/providers/budgets_providers.dart';
import '../features/categories/domain/entities/category_entity.dart';
import '../features/categories/presentation/providers/categories_providers.dart';
import '../features/expenses/domain/entities/expense_entity.dart';
import '../features/expenses/data/services/location_service.dart';
import '../features/expenses/presentation/providers/expenses_providers.dart';

class ExpenseFormPage extends ConsumerStatefulWidget {
  const ExpenseFormPage({super.key});

  @override
  ConsumerState<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends ConsumerState<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _budgetId;
  String? _categoryId;
  String? _photoPath;
  LocationResult? _location;
  bool _loadingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureLocation());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() => _loadingLocation = true);
    final result =
        await ref.read(locationServiceProvider).getCurrentLocation();
    if (mounted) {
      setState(() {
        _location = result;
        _loadingLocation = false;
      });
    }
  }

  Future<void> _pickPhoto(bool fromCamera) async {
    final service = ref.read(receiptImageServiceProvider);
    final path =
        fromCamera ? await service.pickFromCamera() : await service.pickFromGallery();
    if (path != null && mounted) setState(() => _photoPath = path);
  }

  double _availableFor(String budgetId, List<BudgetEntity> budgets) {
    final budget = budgets.where((b) => b.id == budgetId).firstOrNull;
    if (budget == null) return 0;
    final consumed = ref.read(budgetConsumptionProvider(budgetId));
    return (budget.amount - consumed).clamp(0.0, double.infinity);
  }

  Future<void> _submit({required bool asDraft}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_budgetId == null) {
      _toast('Selecciona un presupuesto', isError: true);
      return;
    }
    if (_categoryId == null) {
      _toast('Selecciona una categoría', isError: true);
      return;
    }

    final amount = double.parse(_amountController.text.trim());
    final budgets = ref.read(budgetsStreamProvider).valueOrNull ?? const [];

    // Validación contra presupuesto disponible (solo al enviar, no en borrador).
    if (!asDraft) {
      final available = _availableFor(_budgetId!, budgets);
      if (amount > available) {
        _toast(
          'El monto supera el disponible (\$${available.toStringAsFixed(2)})',
          isError: true,
        );
        return;
      }
    }

    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated) return;
    final user = auth.user;

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
      status: asDraft ? ExpenseStatus.draft : ExpenseStatus.pending,
      createdAt: DateTime.now(),
    );

    await ref
        .read(expenseActionProvider.notifier)
        .create(expense, photoPath: _photoPath);
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.errorColor : AppColors.accentColor,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Solo presupuestos operativos: son los que se consumen con gastos.
    final budgets = (ref.watch(budgetsStreamProvider).valueOrNull ?? const [])
        .where((b) => b.type == BudgetType.operational)
        .toList();
    final allCategories =
        ref.watch(categoriesStreamProvider).valueOrNull ?? const [];

    // Filtrar categorías por las permitidas del presupuesto elegido.
    final selectedBudget = budgets.where((b) => b.id == _budgetId).firstOrNull;
    final categories = (selectedBudget == null ||
            selectedBudget.allowedCategoryIds.isEmpty)
        ? allCategories
        : allCategories
            .where((c) => selectedBudget.allowedCategoryIds.contains(c.id))
            .toList();

    final isLoading = ref.watch(expenseActionProvider) is CrudLoading;

    ref.listen<CrudActionState>(expenseActionProvider, (_, next) {
      if (next is CrudSuccess) {
        _toast(next.message);
        ref.read(expenseActionProvider.notifier).reset();
        if (context.mounted) context.pop();
      } else if (next is CrudError) {
        _toast(next.message, isError: true);
        ref.read(expenseActionProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo gasto'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: AbsorbPointer(
        absorbing: isLoading,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Label('Monto'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: _dec('Ej: 1250.00').copyWith(
                    prefixText: '\$ ',
                    prefixStyle: const TextStyle(color: Colors.white),
                  ),
                  validator: Validators.requiredAmount,
                ),
                const SizedBox(height: 20),
                const _Label('Descripción'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                  decoration: _dec('Ej: Almuerzo con cliente'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresa una descripción'
                      : null,
                ),
                const SizedBox(height: 20),
                const _Label('Presupuesto'),
                const SizedBox(height: 8),
                _BudgetDropdown(
                  budgets: budgets,
                  selected: _budgetId,
                  available: _budgetId != null
                      ? _availableFor(_budgetId!, budgets)
                      : null,
                  onChanged: (v) => setState(() {
                    _budgetId = v;
                    _categoryId = null; // resetear categoría al cambiar
                  }),
                ),
                const SizedBox(height: 20),
                const _Label('Categoría'),
                const SizedBox(height: 8),
                _CategoryDropdown(
                  categories: categories,
                  selected: _categoryId,
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 24),
                const _Label('Foto del recibo'),
                const SizedBox(height: 10),
                _PhotoPicker(
                  photoPath: _photoPath,
                  onCamera: () => _pickPhoto(true),
                  onGallery: () => _pickPhoto(false),
                  onRemove: () => setState(() => _photoPath = null),
                ),
                const SizedBox(height: 24),
                const _Label('Ubicación del gasto'),
                const SizedBox(height: 10),
                _LocationMap(
                  location: _location,
                  loading: _loadingLocation,
                  onRefresh: _captureLocation,
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _submit(asDraft: true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textColor,
                          side:
                              const BorderSide(color: AppColors.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Guardar borrador'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _submit(asDraft: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Enviar',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _BudgetDropdown extends StatelessWidget {
  final List<BudgetEntity> budgets;
  final String? selected;
  final double? available;
  final ValueChanged<String?> onChanged;

  const _BudgetDropdown({
    required this.budgets,
    required this.selected,
    required this.available,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) {
      return _Note(
        'No hay presupuestos operativos. Pide a tu administrador que cree uno.',
      );
    }
    final value = budgets.any((b) => b.id == selected) ? selected : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DropdownBox<String>(
          value: value,
          hint: 'Selecciona un presupuesto',
          items: budgets
              .map((b) => DropdownMenuItem(value: b.id, child: Text(b.name)))
              .toList(),
          onChanged: onChanged,
        ),
        if (available != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              'Disponible: \$${available!.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({
    required this.categories,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return _Note('No hay categorías disponibles para este presupuesto.');
    }
    final value = categories.any((c) => c.id == selected) ? selected : null;
    return _DropdownBox<String>(
      value: value,
      hint: 'Selecciona una categoría',
      items: categories
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _DropdownBox<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownBox({
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
        child: DropdownButton<T>(
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

class _PhotoPicker extends StatelessWidget {
  final String? photoPath;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onRemove;

  const _PhotoPicker({
    required this.photoPath,
    required this.onCamera,
    required this.onGallery,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (photoPath != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(photoPath!),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: _PhotoButton(
            icon: Icons.camera_alt_rounded,
            label: 'Cámara',
            onTap: onCamera,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PhotoButton(
            icon: Icons.photo_library_rounded,
            label: 'Galería',
            onTap: onGallery,
          ),
        ),
      ],
    );
  }
}

class _PhotoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accentColor, size: 26),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textColor, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _LocationMap extends StatelessWidget {
  final LocationResult? location;
  final bool loading;
  final VoidCallback onRefresh;

  const _LocationMap({
    required this.location,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.accentColor),
        ),
      );
    }

    if (location == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Column(
          children: [
            Icon(Icons.location_off_rounded,
                color: AppColors.textColor.withValues(alpha: 0.5), size: 32),
            const SizedBox(height: 8),
            const Text(
              'No se obtuvo la ubicación.',
              style: TextStyle(color: AppColors.textColor),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.accentColor, size: 18),
              label: const Text('Reintentar',
                  style: TextStyle(color: AppColors.accentColor)),
            ),
          ],
        ),
      );
    }

    final point = LatLng(location!.latitude, location!.longitude);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 180,
            child: FlutterMap(
              options: MapOptions(initialCenter: point, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.trakio',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on,
                          color: AppColors.errorColor, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              'Lat ${location!.latitude.toStringAsFixed(5)}, '
              'Lng ${location!.longitude.toStringAsFixed(5)}',
              style: TextStyle(
                color: AppColors.textColor.withValues(alpha: 0.8),
                fontSize: 12.5,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onRefresh,
              child: const Icon(Icons.refresh_rounded,
                  color: AppColors.accentColor, size: 20),
            ),
          ],
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  final String text;
  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Text(
        text,
        style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.8)),
      ),
    );
  }
}
