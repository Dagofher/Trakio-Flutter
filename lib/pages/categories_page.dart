import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../desings/colors.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../features/categories/domain/entities/category_entity.dart';
import '../features/categories/presentation/providers/categories_providers.dart';
import '../features/categories/presentation/providers/category_action_state.dart';
import '../widgets/category_form_sheet.dart';
import '../widgets/category_tile.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final canManage = user?.isAdmin ?? false;
    final companyId = user?.companyId;
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    // Feedback de acciones (crear/editar/eliminar).
    ref.listen<CategoryActionState>(categoryActionProvider, (_, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next is CategoryActionSuccess) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.accentColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(categoryActionProvider.notifier).reset();
      } else if (next is CategoryActionError) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(categoryActionProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: (canManage && companyId != null)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accentColor,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Nueva',
                  style: TextStyle(color: Colors.white)),
              onPressed: () =>
                  showCategoryFormSheet(context, companyId: companyId),
            )
          : null,
      body: categoriesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentColor),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudieron cargar las categorías.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.7)),
            ),
          ),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return _EmptyState(canManage: canManage);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: categories.length,
            itemBuilder: (context, i) {
              final category = categories[i];
              return CategoryTile(
                category: category,
                canManage: canManage,
                onEdit: () => showCategoryFormSheet(
                  context,
                  companyId: category.companyId,
                  existing: category,
                ),
                onDelete: () => _confirmDelete(context, ref, category),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryEntity category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: const Text('Eliminar categoría',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Seguro que deseas eliminar "${category.name}"?',
          style: const TextStyle(color: AppColors.textColor),
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
      await ref.read(categoryActionProvider.notifier).delete(category.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  final bool canManage;
  const _EmptyState({required this.canManage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined,
                size: 64, color: AppColors.textColor.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'Aún no hay categorías',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              canManage
                  ? 'Crea la primera con el botón "Nueva".'
                  : 'El administrador aún no ha creado categorías.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
