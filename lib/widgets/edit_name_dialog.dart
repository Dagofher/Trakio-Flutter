import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/validators.dart';
import '../desings/colors.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';

Future<void> showEditNameDialog(
  BuildContext context,
  WidgetRef ref, {
  required String currentName,
}) {
  return showDialog(
    context: context,
    builder: (_) => _EditNameDialog(currentName: currentName),
  );
}

class _EditNameDialog extends ConsumerStatefulWidget {
  final String currentName;
  const _EditNameDialog({required this.currentName});

  @override
  ConsumerState<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends ConsumerState<_EditNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(accountActionProvider.notifier).updateDisplayName(
          _controller.text.trim(),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceColor,
      title: const Text('Editar nombre',
          style: TextStyle(color: Colors.white, fontSize: 18)),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(r"[a-zA-ZáéíóúüÁÉÍÓÚÜñÑ\s'-]"),
            ),
          ],
          decoration: InputDecoration(
            hintText: 'Tu nombre',
            hintStyle:
                TextStyle(color: AppColors.textColor.withValues(alpha: 0.4)),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accentColor),
            ),
          ),
          validator: Validators.name,
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
