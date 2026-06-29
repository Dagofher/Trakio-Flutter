import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/presentation/crud_action_state.dart';
import '../core/utils/validators.dart';
import '../desings/colors.dart';
import '../features/auth/domain/entities/company_registration.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../widgets/trakio_text_field.dart';

/// Pantalla que aparece tras un login social (GitHub) cuando el usuario aún
/// no pertenece a una empresa. Le permite crear una o unirse con un código.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _isJoining = false;

  @override
  void dispose() {
    _companyController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authProvider);
    if (auth is! AuthNeedsOnboarding) return;

    final company = _isJoining
        ? JoinByCode(_inviteCodeController.text.trim())
        : CreateCompany(_companyController.text.trim());

    await ref.read(accountActionProvider.notifier).completeOnboarding(
          baseUser: auth.user,
          company: company,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final name = auth is AuthNeedsOnboarding ? auth.user.displayName : '';
    final isLoading = ref.watch(accountActionProvider) is CrudLoading;

    ref.listen<CrudActionState>(accountActionProvider, (_, next) {
      if (next is CrudError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(accountActionProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Icon(Icons.apartment_rounded,
                    size: 56, color: AppColors.accentColor),
                const SizedBox(height: 16),
                Text(
                  name.isEmpty ? '¡Casi listo!' : '¡Hola, $name!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Para continuar, crea tu empresa o únete a una con un código.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textColor, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 28),
                _ModeToggle(
                  isJoining: _isJoining,
                  onChanged: (v) => setState(() => _isJoining = v),
                ),
                const SizedBox(height: 16),
                if (_isJoining)
                  TrakioTextField(
                    key: const ValueKey('invite'),
                    label: 'Código de invitación',
                    hint: 'EJ: ACME-7F3K',
                    prefixIcon: Icons.vpn_key_rounded,
                    controller: _inviteCodeController,
                    inputFormatters: [
                      _UpperCaseFormatter(),
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
                        : const Text('Continuar',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.read(authProvider.notifier).signOut(),
                  child: const Text('Cerrar sesión',
                      style: TextStyle(color: AppColors.textColor)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final bool isJoining;
  final ValueChanged<bool> onChanged;

  const _ModeToggle({required this.isJoining, required this.onChanged});

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
          _Option(
            label: 'Crear empresa',
            selected: !isJoining,
            onTap: () => onChanged(false),
          ),
          _Option(
            label: 'Unirme con código',
            selected: isJoining,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.label,
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
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : AppColors.textColor.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
