import 'package:flutter/material.dart';
import '../desings/colors.dart';
import '../features/categories/domain/entities/category_entity.dart';
import '../features/categories/presentation/category_catalog.dart';

class CategoryTile extends StatelessWidget {
  final CategoryEntity category;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryTile({
    super.key,
    required this.category,
    this.canManage = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          _CategoryIcon(iconKey: category.iconKey, color: color),
          const SizedBox(width: 14),
          Expanded(child: _CategoryInfo(category: category)),
          if (canManage) _ManageButtons(onEdit: onEdit, onDelete: onDelete),
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  final String iconKey;
  final Color color;
  const _CategoryIcon({required this.iconKey, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(CategoryCatalog.iconFor(iconKey), size: 22, color: color),
    );
  }
}

class _CategoryInfo extends StatelessWidget {
  final CategoryEntity category;
  const _CategoryInfo({required this.category});

  @override
  Widget build(BuildContext context) {
    final limit = category.defaultLimit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          limit == null
              ? 'Sin límite por defecto'
              : 'Límite: \$${limit.toStringAsFixed(2)}',
          style: TextStyle(
            color: AppColors.textColor.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ManageButtons extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _ManageButtons({this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          color: AppColors.textColor,
          tooltip: 'Editar',
          onPressed: onEdit,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, size: 20),
          color: AppColors.errorColor,
          tooltip: 'Eliminar',
          onPressed: onDelete,
        ),
      ],
    );
  }
}
