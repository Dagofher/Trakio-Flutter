import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/presentation/crud_action_state.dart';
import '../core/utils/validators.dart';
import '../desings/colors.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../features/departments/domain/entities/department_entity.dart';
import '../features/departments/presentation/providers/departments_providers.dart';

class DepartmentsPage extends ConsumerWidget {
  const DepartmentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;
    final canManage = user?.isAdmin ?? false;
    final companyId = user?.companyId;
    final departmentsAsync = ref.watch(departmentsStreamProvider);

    ref.listen<CrudActionState>(departmentActionProvider, (_, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next is CrudSuccess) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.accentColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(departmentActionProvider.notifier).reset();
      } else if (next is CrudError) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(departmentActionProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Departamentos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: (canManage && companyId != null)
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.accentColor,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Nuevo',
                  style: TextStyle(color: Colors.white)),
              onPressed: () => _showForm(context, ref, companyId),
            )
          : null,
      body: departmentsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentColor),
        ),
        error: (err, stack) => Center(
          child: Text(
            'No se pudieron cargar los departamentos.',
            style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.7)),
          ),
        ),
        data: (departments) {
          if (departments.isEmpty) {
            return _EmptyState(canManage: canManage);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: departments.length,
            itemBuilder: (context, i) {
              final dept = departments[i];
              return _DepartmentTile(
                department: dept,
                canManage: canManage,
                onEdit: () =>
                    _showForm(context, ref, dept.companyId, existing: dept),
                onDelete: () => _confirmDelete(context, ref, dept),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showForm(
    BuildContext context,
    WidgetRef ref,
    String companyId, {
    DepartmentEntity? existing,
  }) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _DepartmentNameDialog(initialName: existing?.name ?? ''),
    );

    if (name != null && name.isNotEmpty) {
      final dept = (existing ??
              DepartmentEntity(id: '', companyId: companyId, name: ''))
          .copyWith(name: name);
      await ref.read(departmentActionProvider.notifier).save(dept);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DepartmentEntity dept,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: const Text('Eliminar departamento',
            style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Seguro que deseas eliminar "${dept.name}"?',
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
      await ref.read(departmentActionProvider.notifier).delete(dept.id);
    }
  }
}

class _DepartmentTile extends StatelessWidget {
  final DepartmentEntity department;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DepartmentTile({
    required this.department,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.apartment_rounded,
                color: AppColors.accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              department.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (canManage) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.textColor,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              color: AppColors.errorColor,
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
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
            Icon(Icons.apartment_outlined,
                size: 64, color: AppColors.textColor.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text(
              'Aún no hay departamentos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              canManage
                  ? 'Crea el primero con el botón "Nuevo".'
                  : 'El administrador aún no ha creado departamentos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Diálogo para crear/editar el nombre de un departamento.
/// Es StatefulWidget para que el controller se libere de forma segura en
/// dispose() (evita "TextEditingController used after being disposed").
class _DepartmentNameDialog extends StatefulWidget {
  final String initialName;
  const _DepartmentNameDialog({required this.initialName});

  @override
  State<_DepartmentNameDialog> createState() => _DepartmentNameDialogState();
}

class _DepartmentNameDialogState extends State<_DepartmentNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName.isNotEmpty;
    return AlertDialog(
      backgroundColor: AppColors.surfaceColor,
      title: Text(
        isEditing ? 'Editar departamento' : 'Nuevo departamento',
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'Ej: Ventas',
            hintStyle:
                TextStyle(color: AppColors.textColor.withValues(alpha: 0.4)),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentColor),
            ),
          ),
          validator: Validators.categoryName,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: AppColors.textColor)),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Guardar',
              style: TextStyle(color: AppColors.accentColor)),
        ),
      ],
    );
  }
}
