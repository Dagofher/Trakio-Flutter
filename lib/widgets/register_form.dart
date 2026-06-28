import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/validators.dart';
import '../desings/colors.dart';
import '../features/auth/domain/entities/company_registration.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import 'trakio_text_field.dart';

class RegisterForm extends ConsumerStatefulWidget {
  const RegisterForm({super.key});

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  /// false = crear empresa nueva (Admin); true = unirse con código (Employee).
  bool _isJoining = false;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _inviteCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setMode(bool joining) {
    if (_isJoining == joining) return;
    setState(() => _isJoining = joining);
  }

  Future<void> _onRegisterPressed() async {
    if (!_formKey.currentState!.validate()) return;
    final company = _isJoining
        ? JoinByCode(_inviteCodeController.text.trim())
        : CreateCompany(_companyController.text.trim());
    ref.read(authProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _nameController.text.trim(),
          company: company,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider) is AuthLoading;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthRegistrationSuccess) {
        context.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cuenta creada. Inicia sesión con tus credenciales.'),
            backgroundColor: AppColors.accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppColors.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TrakioTextField(
            label: 'Nombre completo',
            hint: 'Juan Pérez',
            prefixIcon: Icons.person_outline_rounded,
            controller: _nameController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r"[a-zA-ZáéíóúüÁÉÍÓÚÜñÑ\s'-]"),
              ),
            ],
            validator: Validators.name,
          ),
          const SizedBox(height: 24),
          _CompanyModeSelector(isJoining: _isJoining, onChanged: _setMode),
          const SizedBox(height: 16),
          // Campo condicional según el modo elegido.
          if (_isJoining)
            TrakioTextField(
              key: const ValueKey('invite'),
              label: 'Código de invitación',
              hint: 'EJ: ACME-7F3K',
              prefixIcon: Icons.vpn_key_rounded,
              controller: _inviteCodeController,
              inputFormatters: [
                UpperCaseTextFormatter(),
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
              ],
              validator: Validators.inviteCode,
            )
          else
            TrakioTextField(
              key: const ValueKey('company'),
              label: 'Nombre de la empresa',
              hint: 'Tu empresa',
              prefixIcon: Icons.business_rounded,
              controller: _companyController,
              validator: Validators.company,
            ),
          const SizedBox(height: 20),
          TrakioTextField(
            label: 'Correo corporativo',
            hint: 'usuario@empresa.com',
            prefixIcon: Icons.email_outlined,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 20),
          TrakioTextField(
            label: 'Contraseña',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            controller: _passwordController,
            isPassword: true,
            validator: Validators.strongPassword,
          ),
          const SizedBox(height: 20),
          TrakioTextField(
            label: 'Confirmar contraseña',
            hint: '••••••••',
            prefixIcon: Icons.lock_outline_rounded,
            controller: _confirmPasswordController,
            isPassword: true,
            validator: (v) =>
                Validators.confirmPassword(v, _passwordController.text),
          ),
          const SizedBox(height: 32),
          _RegisterButton(isLoading: isLoading, onPressed: _onRegisterPressed),
        ],
      ),
    );
  }
}

/// Fuerza el texto a mayúsculas (para el código de invitación).
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _CompanyModeSelector extends StatelessWidget {
  final bool isJoining;
  final ValueChanged<bool> onChanged;

  const _CompanyModeSelector({required this.isJoining, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          _ModeOption(
            label: 'Crear empresa',
            icon: Icons.add_business_rounded,
            selected: !isJoining,
            onTap: () => onChanged(false),
          ),
          _ModeOption(
            label: 'Unirme con código',
            icon: Icons.group_add_rounded,
            selected: isJoining,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : AppColors.textColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : AppColors.textColor.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _RegisterButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentColor,
          disabledBackgroundColor: AppColors.accentColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Crear cuenta',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
