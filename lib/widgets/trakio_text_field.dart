import 'package:flutter/material.dart';
import '../desings/colors.dart';

class TrakioTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const TrakioTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<TrakioTextField> createState() => _TrakioTextFieldState();
}

class _TrakioTextFieldState extends State<TrakioTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: widget.label),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscureText,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: AppColors.textColor.withOpacity(0.4),
              fontSize: 15,
            ),
            prefixIcon: Icon(
              widget.prefixIcon,
              color: AppColors.textColor.withOpacity(0.5),
              size: 20,
            ),
            suffixIcon: widget.isPassword
                ? _PasswordToggleButton(
                    isObscured: _obscureText,
                    onToggle: () => setState(() => _obscureText = !_obscureText),
                  )
                : null,
            filled: true,
            fillColor: AppColors.surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: _buildBorder(AppColors.borderColor),
            enabledBorder: _buildBorder(AppColors.borderColor),
            focusedBorder: _buildBorder(AppColors.accentColor),
            errorBorder: _buildBorder(AppColors.errorColor),
            focusedErrorBorder: _buildBorder(AppColors.errorColor),
            errorStyle: const TextStyle(
              color: AppColors.errorColor,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textColor,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _PasswordToggleButton extends StatelessWidget {
  final bool isObscured;
  final VoidCallback onToggle;

  const _PasswordToggleButton({
    required this.isObscured,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
        color: AppColors.textColor.withOpacity(0.5),
        size: 20,
      ),
    );
  }
}