import 'package:flutter/material.dart';
import '../desings/colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AppLogoIcon(),
        const SizedBox(height: 24),
        _AppTitle(),
        const SizedBox(height: 8),
        _AppSubtitle(),
      ],
    );
  }
}




class _AppLogoIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.accentColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.track_changes_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Trakio',
      style: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    );
  }
}

class _AppSubtitle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(
      'Gestiona los gastos de tu empresa\ndesde cualquier lugar.',
      style: TextStyle(
        color: AppColors.textColor,
        fontSize: 15,
        height: 1.5,
      ),
    );
  }
}
