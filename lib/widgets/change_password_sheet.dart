import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/presentation/crud_action_state.dart';
import '../core/utils/validators.dart';
import '../desings/colors.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import 'trakio_text_field.dart';

Future<void> showChangePasswordSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.backgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ChangePasswordSheet(),
  );
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(accountActionProvider.notifier).changePassword(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(accountActionProvider) is CrudLoading;

    // Cerrar la hoja cuando el cambio sea exitoso.
    ref.listen<CrudActionState>(accountActionProvider, (_, next) {
      if (next is CrudSuccess && mounted) Navigator.pop(context);
    });

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
                const Text('Cambiar contraseña',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                TrakioTextField(
                  label: 'Contraseña actual',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  controller: _currentController,
                  isPassword: true,
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Ingresa tu contraseña actual'
                      : null,
                ),
                const SizedBox(height: 16),
                TrakioTextField(
                  label: 'Nueva contraseña',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_reset_rounded,
                  controller: _newController,
                  isPassword: true,
                  validator: Validators.strongPassword,
                ),
                const SizedBox(height: 16),
                TrakioTextField(
                  label: 'Confirmar nueva contraseña',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_reset_rounded,
                  controller: _confirmController,
                  isPassword: true,
                  validator: (v) =>
                      Validators.confirmPassword(v, _newController.text),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      disabledBackgroundColor:
                          AppColors.accentColor.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Actualizar contraseña',
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
