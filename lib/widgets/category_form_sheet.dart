import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/validators.dart';
import '../desings/colors.dart';
import '../features/categories/domain/entities/category_entity.dart';
import '../features/categories/presentation/category_catalog.dart';
import '../features/categories/presentation/providers/categories_providers.dart';

/// Muestra el formulario de crear/editar categoría como bottom sheet.
Future<void> showCategoryFormSheet(
  BuildContext context, {
  required String companyId,
  CategoryEntity? existing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _CategoryFormSheet(companyId: companyId, existing: existing),
    ),
  );
}

class _CategoryFormSheet extends ConsumerStatefulWidget {
  final String companyId;
  final CategoryEntity? existing;

  const _CategoryFormSheet({required this.companyId, this.existing});

  @override
  ConsumerState<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _limitController;
  late String _iconKey;
  late int _colorValue;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameController = TextEditingController(text: c?.name ?? '');
    _limitController = TextEditingController(
      text: c?.defaultLimit != null ? c!.defaultLimit!.toStringAsFixed(2) : '',
    );
    _iconKey = c?.iconKey ?? CategoryCatalog.defaultIconKey;
    _colorValue = c?.colorValue ?? CategoryCatalog.defaultColor;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    final limitText = _limitController.text.trim();
    final category = CategoryEntity(
      id: widget.existing?.id ?? '',
      companyId: widget.companyId,
      name: _nameController.text.trim(),
      iconKey: _iconKey,
      colorValue: _colorValue,
      defaultLimit: limitText.isEmpty ? null : double.parse(limitText),
    );
    await ref.read(categoryActionProvider.notifier).save(category);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                _isEditing ? 'Editar categoría' : 'Nueva categoría',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _Label('Nombre'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Ej: Viáticos'),
                validator: Validators.categoryName,
              ),
              const SizedBox(height: 20),
              _Label('Límite por defecto (opcional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _limitController,
                style: const TextStyle(color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: _inputDecoration('Ej: 5000.00').copyWith(
                  prefixText: '\$ ',
                  prefixStyle: const TextStyle(color: Colors.white),
                ),
                validator: Validators.optionalAmount,
              ),
              const SizedBox(height: 20),
              _Label('Ícono'),
              const SizedBox(height: 10),
              _IconPicker(
                selected: _iconKey,
                color: Color(_colorValue),
                onSelected: (k) => setState(() => _iconKey = k),
              ),
              const SizedBox(height: 20),
              _Label('Color'),
              const SizedBox(height: 10),
              _ColorPicker(
                selected: _colorValue,
                onSelected: (c) => setState(() => _colorValue = c),
              ),
              const SizedBox(height: 28),
              _SaveButton(isEditing: _isEditing, onPressed: _onSave),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
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

class _IconPicker extends StatelessWidget {
  final String selected;
  final Color color;
  final ValueChanged<String> onSelected;

  const _IconPicker({
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final entries = CategoryCatalog.icons.entries.toList();
    return SizedBox(
      height: 100,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: entries.length,
        itemBuilder: (context, i) {
          final key = entries[i].key;
          final isSelected = key == selected;
          return GestureDetector(
            onTap: () => onSelected(key),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color : AppColors.borderColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                entries[i].value,
                size: 20,
                color: isSelected ? color : AppColors.textColor,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _ColorPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: CategoryCatalog.colors.map((value) {
        final isSelected = value == selected;
        return GestureDetector(
          onTap: () => onSelected(value),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(value),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
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
          isEditing ? 'Guardar cambios' : 'Crear categoría',
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
